class DataSyncJob < ApplicationJob
  queue_as :default

  def perform(spreadsheet_id = nil)
    spreadsheets = fetch_spreadsheets(spreadsheet_id)
    results = []

    spreadsheets.each do |spreadsheet|
      spreadsheet.sheets.each do |sheet|
        result = sync_sheet(spreadsheet, sheet)
        results << build_result(spreadsheet, sheet, result)
        spreadsheet.log_sync_result(sheet, result)
      end
    end

    results
  end

  private

  def fetch_spreadsheets(spreadsheet_id)
    spreadsheet_id ? Spreadsheet.where(id: spreadsheet_id) : Spreadsheet.active
  end

  def sync_sheet(spreadsheet, sheet)
    service = SpreadsheetSyncService.new(spreadsheet, sheet.sheet_name)
    service.sync_data
  end

  def build_result(spreadsheet, sheet, sync_result)
    {
      spreadsheet: spreadsheet.name,
      sheet: sheet.sheet_name,
      result: sync_result
    }
  end
end
