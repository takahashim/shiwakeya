class DataSyncJob < ApplicationJob
  queue_as :default

  def perform(spreadsheet_id = nil)
    spreadsheets = spreadsheet_id ?
      Spreadsheet.where(id: spreadsheet_id) :
      Spreadsheet.active

    results = []

    spreadsheets.each do |spreadsheet|
      spreadsheet.sheets.each do |sheet|
        service = SpreadsheetSyncService.new(spreadsheet, sheet.sheet_name)
        result = service.sync_data

        results << {
          spreadsheet: spreadsheet.name,
          sheet: sheet.sheet_name,
          result: result
        }

        log_sync_result(spreadsheet, sheet, result)
      end
    end

    results
  end

  private

  def log_sync_result(spreadsheet, sheet, result)
    if result[:errors].any?
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
