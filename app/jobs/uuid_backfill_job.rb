class UuidBackfillJob < ApplicationJob
  queue_as :low_priority

  def perform(spreadsheet_id = nil)
    spreadsheets = fetch_spreadsheets(spreadsheet_id)
    results = []

    spreadsheets.each do |spreadsheet|
      service = UuidBackfillService.new(spreadsheet)

      if service.should_skip_backfill?
        handle_skipped_spreadsheet(spreadsheet)
        next
      end

      spreadsheet_results = service.perform
      results.concat(spreadsheet_results)
    end

    results
  end

  private

  def fetch_spreadsheets(spreadsheet_id)
    spreadsheet_id ? Spreadsheet.where(id: spreadsheet_id) : Spreadsheet.active
  end

  def handle_skipped_spreadsheet(spreadsheet)
    Rails.logger.info("Skipping UUID backfill for #{spreadsheet.name} - recent activity detected")
    self.class.set(wait: 10.minutes).perform_later(spreadsheet.id)
  end
end
