class UuidBackfillJob < ApplicationJob
  queue_as :low_priority

  # 編集アクティビティ監視
  def perform(spreadsheet_id = nil)
    spreadsheets = spreadsheet_id ?
      Spreadsheet.where(id: spreadsheet_id) :
      Spreadsheet.active

    results = []

    spreadsheets.each do |spreadsheet|
      # アクティビティチェック
      if sheet_recently_edited?(spreadsheet)
        Rails.logger.info("Skipping UUID backfill for #{spreadsheet.name} - recent activity detected")
        self.class.set(wait: 10.minutes).perform_later(spreadsheet.id)
        next
      end

      spreadsheet.sheets.each do |sheet|
        service = SpreadsheetSyncService.new(spreadsheet, sheet.sheet_name)

        # UUID未設定の行を検出
        missing_uuids = service.detect_missing_uuids

        if missing_uuids.any?
          Rails.logger.info("Found #{missing_uuids.size} rows without UUID in #{spreadsheet.name}/#{sheet.sheet_name}")

          # 最大10件ずつ処理（API制限対策）
          batches = missing_uuids.each_slice(10)

          batches.each_with_index do |batch, batch_index|
            result = service.backfill_uuids(batch)
            results << {
              spreadsheet: spreadsheet.name,
              sheet: sheet.sheet_name,
              batch: batch_index + 1,
              result: result
            }

            if result[:errors].any?
              Rails.logger.error(
                "UUID backfill errors for #{spreadsheet.name}/#{sheet.sheet_name} batch #{batch_index + 1}: " \
                "#{result[:errors].join(', ')}"
              )
            else
              Rails.logger.info(
                "Successfully generated #{result[:count]} UUIDs for #{spreadsheet.name}/#{sheet.sheet_name} batch #{batch_index + 1}"
              )
            end

            # バッチ間で少し待機
            sleep 1 if batches.size > 1
          end
        end
      end
    end

    results
  end

  private

  def sheet_recently_edited?(spreadsheet)
    # 最後の同期から5分以内に編集があったかチェック
    last_sync = SpreadsheetSync
      .where(spreadsheet_id: spreadsheet.id)
      .maximum(:last_synced_at)

    return false unless last_sync

    # Google Drive APIで最終更新時刻を確認
    begin
      require "google/apis/drive_v3"

      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = google_authorization

      file = service.get_file(
        spreadsheet.spreadsheet_id,
        fields: "modifiedTime"
      )

      last_modified = Time.parse(file.modified_time)

      # 5分以内に編集されていたらtrue
      last_modified > 5.minutes.ago
    rescue => e
      Rails.logger.error("Failed to check sheet activity: #{e.message}")
      # エラー時は安全側に倒す（編集中と見なす）
      true
    end
  end

  def google_authorization
    # GoogleSheetsClientから認証情報を取得
    GoogleSheetsClient.client.authorization
  end
end
