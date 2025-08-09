class ServiceSpreadsheet < ApplicationRecord
  has_many :service_sheets, dependent: :destroy
  has_many :user_spreadsheet_permissions, dependent: :destroy
  has_many :permitted_users, through: :user_spreadsheet_permissions, source: :user

  validates :name, presence: true
  validates :spreadsheet_id, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }

  def sync_sheets
    service = GoogleSheetsClient.new
    spreadsheet = service.get_spreadsheet(spreadsheet_id)

    return unless spreadsheet

    # 既存のシート情報を更新または作成
    spreadsheet.sheets.each do |sheet|
      sheet_name = sheet.properties.title
      service_sheet = service_sheets.find_or_initialize_by(sheet_name: sheet_name)

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

      service_sheet.update!(
        purpose: purpose,
        last_synced_at: Time.current
      )
    end
  end

  def fetch_sheet_data(sheet_name)
    service = GoogleSheetsClient.new
    # シート名に特殊文字が含まれる場合はシングルクォートでエスケープ
    escaped_sheet_name = sheet_name.include?(" ") || sheet_name.include?("!") ? "'#{sheet_name.gsub("'", "''")}'" : sheet_name
    range = "#{escaped_sheet_name}!A:Z"
    service.get_values(range, spreadsheet_id)
  rescue => e
    Rails.logger.error "Error fetching sheet data for #{sheet_name} from spreadsheet #{spreadsheet_id}: #{e.message}"
    Rails.logger.error "Range used: #{range}" if defined?(range)
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def update_sheet_data(sheet_name, values)
    service = GoogleSheetsClient.new
    # シート名に特殊文字が含まれる場合はシングルクォートでエスケープ
    escaped_sheet_name = sheet_name.include?(" ") || sheet_name.include?("!") ? "'#{sheet_name.gsub("'", "''")}'" : sheet_name
    range = "#{escaped_sheet_name}!A1"
    service.update_values(range, values, spreadsheet_id)
  end
end
