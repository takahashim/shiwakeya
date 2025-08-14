class UuidBackfillJob < ApplicationJob
  queue_as :low_priority

  def perform(spreadsheet_id = nil)
    spreadsheets = Spreadsheet.for_sync(id: spreadsheet_id)

    spreadsheets.each do |spreadsheet|
      UuidBackfillService.new(spreadsheet).perform
    end
  end
end
