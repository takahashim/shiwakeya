class SpreadsheetSyncService
  attr_reader :spreadsheet, :sheet_name

  def initialize(spreadsheet, sheet_name = nil)
    @spreadsheet = spreadsheet
    @sheet_name = sheet_name || "Sheet1"
  end

  # データ同期（UUID有りの行のみ）
  def sync_data
    sheet_data = fetch_sheet_data
    results = { synced: 0, skipped: 0, errors: [] }

    # 既存レコードを一旦全て削除済みマーク
    existing_syncs = SpreadsheetSync.by_sheet(spreadsheet.id, sheet_name).active
    existing_uuids = existing_syncs.pluck(:uuid)

    sheet_data.each_with_index do |row, index|
      next if index == 0 # ヘッダー行スキップ

      uuid = row[0] # A列がUUID
      next if uuid.blank? # UUIDなしはスキップ

      begin
        sync_record = SpreadsheetSync.find_or_initialize_by(
          uuid: uuid,
          spreadsheet_id: spreadsheet.id,
          sheet_name: sheet_name
        )

        if sync_record.new_record? || sync_record.data_changed?(row)
          sync_record.update_from_sheet(row, index + 1)
          results[:synced] += 1
        else
          results[:skipped] += 1
        end

        existing_uuids.delete(uuid)
      rescue => e
        results[:errors] << { row: index + 1, error: e.message }
      end
    end

    # シートから消えたレコードを削除済みマーク
    SpreadsheetSync.where(uuid: existing_uuids).update_all(sync_status: :deleted)

    results
  end

  # UUID未設定の行を検出（書き込みはしない）
  def detect_missing_uuids
    sheet_data = fetch_sheet_data
    missing = []

    sheet_data.each_with_index do |row, index|
      next if index == 0 # ヘッダー行スキップ

      uuid = row[0]
      # UUIDが空で、他にデータがある行
      if uuid.blank? && row[1..].any?(&:present?)
        missing << {
          row_number: index + 1,
          row_data: row
        }
      end
    end

    missing
  end

  # UUID埋め込み（バッチ処理）
  def backfill_uuids(rows_to_update = nil)
    rows_to_update ||= detect_missing_uuids
    return { count: 0, errors: [] } if rows_to_update.empty?

    # Google Sheets APIのバッチ更新用データ構築
    updates = rows_to_update.map do |row_info|
      {
        range: "#{sheet_name}!A#{row_info[:row_number]}",
        values: [ [ Uuidv7Generator.generate ] ]
      }
    end

    # バッチ更新実行
    begin
      batch_update_values(updates)
      { count: updates.size, errors: [] }
    rescue => e
      { count: 0, errors: [ e.message ] }
    end
  end

  private

  def fetch_sheet_data
    spreadsheet.fetch_sheet_data(sheet_name)
  end

  def batch_update_values(updates)
    client = SpreadsheetClient.new(spreadsheet.spreadsheet_id)
    client.batch_update_values(updates)
  end
end
