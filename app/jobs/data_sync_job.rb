class DataSyncJob < ApplicationJob
  queue_as :default

  def perform(spreadsheet_id = nil)
    spreadsheets = Spreadsheet.for_sync(id: spreadsheet_id)

    spreadsheets.each do |spreadsheet|
      spreadsheet.sheets.each do |sheet|
        result = sync_sheet(spreadsheet, sheet)

        log_sync_result(spreadsheet, sheet, result)
      end
    end
  end

  private

  def sync_sheet(spreadsheet, sheet)
    spreadsheet.sync_sheet(sheet)
  rescue InvalidSheetDataError => e
    Rails.logger.error("Invalid sheet format: #{e.message}")
    error_messages = e.sheet_data.errors.full_messages
    { errors: error_messages, synced: 0, skipped: 0 }
  end

  def log_sync_result(spreadsheet, sheet, result)
    if result[:errors].present? && result[:errors].any?
      Rails.logger.error(
        "Sync errors for #{spreadsheet.name}/#{sheet.sheet_name}: " \
        "#{result[:errors].to_json}"
      )
    else
      Rails.logger.info(
        "Synced #{spreadsheet.name}/#{sheet.sheet_name}: " \
        "#{result[:synced]} updated, #{result[:skipped]} skipped"
      )
    end
  end
end
