class ServiceSheet < ApplicationRecord
  belongs_to :service_spreadsheet

  validates :sheet_name, presence: true

  scope :by_purpose, ->(purpose) { where(purpose: purpose) }
  scope :recently_synced, -> { order(last_synced_at: :desc) }

  def sync_data
    values = service_spreadsheet.fetch_sheet_data(sheet_name)
    
    update!(
      data: values.to_json,
      last_synced_at: Time.current
    )
    
    values
  rescue => e
    Rails.logger.error "Error syncing sheet data for #{sheet_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def parsed_data
    return [] unless data.present?
    JSON.parse(data)
  rescue JSON::ParserError
    []
  end

  def write_data(values)
    result = service_spreadsheet.update_sheet_data(sheet_name, values)
    
    if result
      update!(
        data: values.to_json,
        last_synced_at: Time.current
      )
    end
    
    result
  end

  def append_row(row_data)
    service = ServiceAccountSheetsService.new
    # シート名に特殊文字が含まれる場合はシングルクォートでエスケープ
    escaped_sheet_name = sheet_name.include?(' ') || sheet_name.include?('!') ? "'#{sheet_name.gsub("'", "''")}'" : sheet_name
    range = "#{escaped_sheet_name}!A:Z"
    service.append_values(range, [row_data], service_spreadsheet.spreadsheet_id)
  end

  def clear_all_data
    service = ServiceAccountSheetsService.new
    # シート名に特殊文字が含まれる場合はシングルクォートでエスケープ
    escaped_sheet_name = sheet_name.include?(' ') || sheet_name.include?('!') ? "'#{sheet_name.gsub("'", "''")}'" : sheet_name
    range = "#{escaped_sheet_name}!A:Z"
    service.clear_values(range, service_spreadsheet.spreadsheet_id)
  end
end