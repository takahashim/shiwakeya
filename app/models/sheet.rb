class Sheet < ApplicationRecord
  belongs_to :spreadsheet

  validates :sheet_name, presence: true

  scope :by_purpose, ->(purpose) { where(purpose: purpose) }
  scope :recently_synced, -> { order(last_synced_at: :desc) }

  REQUIRED_HEADER_COLUMN_A = "UUID".freeze

  def sync_rows
    raw_data = spreadsheet.fetch_sheet_data(sheet_name)
    headers, rows = parse_raw_data(raw_data)

    validate_headers(headers)
    if errors.any?
      raise InvalidSheetError.new(self)
    end

    synced_uuids = []
    results = { synced: 0, skipped: 0, errors: [] }

    SyncedRow.transaction do
      process_rows_with_uuid(rows).each do |row, row_index|
        uuid = uuid_for_row(row)
        row_number = row_index + 1  # Convert 0-based index to 1-based row number
        synced_uuids << uuid

        begin
          sync_record = spreadsheet.synced_rows.find_or_initialize_by(
            uuid: uuid,
            sheet_name: sheet_name
          )

          if sync_record.should_update?(row)
            sync_record.update_from_sheet(row, row_number + 1)  # row_numberは1-based
            results[:synced] += 1
          else
            results[:skipped] += 1
          end
        rescue => e
          results[:errors] << { row: row_number + 1, error: e.message }
        end
      end

      # 存在しなくなったレコードを削除済みに
      SyncedRow.mark_missing_as_deleted(spreadsheet.id, sheet_name, synced_uuids)
    end

    update!(last_synced_at: Time.current)
    results
  rescue => e
    Rails.logger.error "Error syncing sheet rows for #{sheet_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def rows_data
    spreadsheet.synced_rows
      .by_sheet(spreadsheet.id, sheet_name)
      .active
      .order(:row_number)
      .pluck(:row_data)
      .map { |data| JSON.parse(data) rescue [] }
  end

  def write_data(values)
    result = spreadsheet.update_sheet_data(sheet_name, values)

    if result
      # Google Sheetsに書き込み後、SyncedRowも更新
      sync_rows
    end

    result
  end

  def append_row(row_data)
    client = SpreadsheetClient.new(spreadsheet.spreadsheet_id)
    # シート名に特殊文字が含まれる場合はシングルクォートでエスケープ
    escaped_sheet_name = sheet_name.include?(" ") || sheet_name.include?("!") ? "'#{sheet_name.gsub("'", "''")}'" : sheet_name
    range = "#{escaped_sheet_name}!A:Z"
    client.append_values(range, [ row_data ])
  end

  # ローカルのデータベースに保存されているデータをクリア（スプレッドシートのデータは削除しない）
  def clear_local_data
    spreadsheet.synced_rows
      .by_sheet(spreadsheet.id, sheet_name)
      .destroy_all
    update!(last_synced_at: nil)
  end

  # UUID欠落行を検出（UuidBackfillServiceから使用）
  def missing_uuid_rows
    raw_data = spreadsheet.fetch_sheet_data(sheet_name)
    headers, rows = parse_raw_data(raw_data)

    validate_headers(headers)
    return [] if errors.any?

    rows.each_with_index.filter_map do |row, index|
      if row[0].blank? && row[1..].any?(&:present?)
        { row_number: index + 2 }  # +2 because headers are row 1
      end
    end
  end

  def uuid_for_row(row)
    row[0] if row.present?
  end

  private

  def parse_raw_data(raw_data)
    if raw_data.present? && raw_data.is_a?(Array)
      [ raw_data.first, raw_data[1..] || [] ]
    else
      [ [], [] ]
    end
  end

  def validate_headers(headers)
    return if headers.blank?

    if headers[0] != REQUIRED_HEADER_COLUMN_A
      errors.add(:base, "A列のヘッダーは'#{REQUIRED_HEADER_COLUMN_A}'である必要があります（現在: '#{headers[0]}'）")
    end
  end

  def process_rows_with_uuid(rows)
    return [] unless rows

    rows.each_with_index.filter_map do |row, index|
      [ row, index ] if row[0].present?
    end
  end
end
