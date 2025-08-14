class Spreadsheet < ApplicationRecord
  has_many :sheets, dependent: :destroy
  has_many :synced_rows, dependent: :destroy
  has_many :user_spreadsheet_permissions, dependent: :destroy
  has_many :permitted_users, through: :user_spreadsheet_permissions, source: :user

  validates :name, presence: true
  validates :spreadsheet_id, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }

  # 同期対象のスプレッドシートを取得
  # @param id [Integer, nil] 特定のスプレッドシートID（nilの場合は全アクティブ）
  # @return [ActiveRecord::Relation]
  def self.for_sync(id: nil)
    id ? where(id: id) : active
  end

  def sync_sheets
    client = SpreadsheetClient.new(spreadsheet_id)
    spreadsheet = client.spreadsheet

    return unless spreadsheet

    # 既存のシート情報を更新または作成
    spreadsheet.sheets.each do |sheet|
      sheet_name = sheet.properties.title
      sheet = sheets.find_or_initialize_by(sheet_name: sheet_name)

      # シートの用途を推測（シート名から判断）
      purpose = case sheet_name.downcase
      when /input/, /入力/
                  "input"
      when /output/, /出力/
                  "output"
      when /config/, /設定/
                  "config"
      when /master/, /マスタ/
                  "master"
      else
                  "data"
      end

      sheet.update!(
        purpose: purpose,
        last_synced_at: Time.current
      )
    end
  end

  def fetch_sheet_data(sheet_name)
    client = SpreadsheetClient.new(spreadsheet_id)
    client.fetch_sheet_data(sheet_name)
  rescue => e
    Rails.logger.error "Error fetching sheet data for #{sheet_name} from spreadsheet #{spreadsheet_id}: #{e.message}"
    Rails.logger.error "Range used: #{range}" if defined?(range)
    Rails.logger.error e.backtrace.join("\n")
    raise
  end


  # シートのデータを同期
  def sync_sheet(sheet)
    sheet_data = sheet.as_sheet_data

    unless sheet_data.valid?
      raise InvalidSheetDataError.new(sheet_data)
    end

    synced_uuids = []
    results = { synced: 0, skipped: 0, errors: [] }

    SyncedRow.transaction do
      sheet_data.rows_with_uuid.each do |row, row_number|
        uuid = sheet_data.uuid_for_row(row)
        synced_uuids << uuid

        begin
          sync_record = synced_rows.find_or_initialize_by(
            uuid: uuid,
            sheet_name: sheet.sheet_name
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
      SyncedRow.mark_missing_as_deleted(id, sheet.sheet_name, synced_uuids)
    end

    results
  end

  def update_sheet_data(sheet_name, values)
    client = SpreadsheetClient.new(spreadsheet_id)
    client.update_sheet_data(sheet_name, values)
  end

  def recently_edited?(threshold: 5.minutes)
    last_modified_time > threshold.ago
  rescue => e
    Rails.logger.error("Failed to check sheet activity: #{e.message}")
    true
  end

  def last_modified_time
    drive_service.get_last_modified_time(spreadsheet_id)
  end

  private

  def drive_service
    @drive_service ||= DriveService.new
  end
end
