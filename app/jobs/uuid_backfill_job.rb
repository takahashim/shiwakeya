class UuidBackfillJob < ApplicationJob
  queue_as :low_priority

  def perform(spreadsheet_id = nil)
    spreadsheets = Spreadsheet.for_sync(id: spreadsheet_id)

    spreadsheets.each do |spreadsheet|
      service = UuidBackfillService.new(spreadsheet)

      if service.should_skip_backfill?
        Rails.logger.info("Skipping UUID backfill for #{spreadsheet.name} - recent activity detected")
        next
      end

      service.perform
    end
  end
end
