class UuidBackfillService
  BATCH_SIZE = 10
  BATCH_WAIT_TIME = 1

  attr_reader :spreadsheet

  def initialize(spreadsheet)
    @spreadsheet = spreadsheet
  end

  def perform
    results = []

    return results if should_skip_backfill?

    spreadsheet.sheets.each do |sheet|
      sheet_results = process_sheet(sheet)
      results.concat(sheet_results) if sheet_results.any?
    end

    results
  end

  def should_skip_backfill?
    spreadsheet.recently_edited?
  end

  private

  def process_sheet(sheet)
    results = []
    sync_service = SpreadsheetSyncService.new(spreadsheet, sheet.sheet_name)
    missing_uuids = sync_service.detect_missing_uuids

    return results unless missing_uuids.any?

    Rails.logger.info(
      "Found #{missing_uuids.size} rows without UUID in #{spreadsheet.name}/#{sheet.sheet_name}"
    )

    process_batches(missing_uuids, sheet, sync_service, results)
    results
  end

  def process_batches(missing_uuids, sheet, sync_service, results)
    batches = missing_uuids.each_slice(BATCH_SIZE)

    batches.each_with_index do |batch, batch_index|
      result = sync_service.backfill_uuids(batch)

      batch_result = {
        spreadsheet: spreadsheet.name,
        sheet: sheet.sheet_name,
        batch: batch_index + 1,
        result: result
      }

      results << batch_result
      log_batch_result(batch_result)

      sleep BATCH_WAIT_TIME if batches.size > 1 && batch_index < batches.size - 1
    end
  end

  def log_batch_result(batch_result)
    result = batch_result[:result]
    identifier = "#{batch_result[:spreadsheet]}/#{batch_result[:sheet]} batch #{batch_result[:batch]}"

    if result[:errors].present? && result[:errors].any?
      Rails.logger.error(
        "UUID backfill errors for #{identifier}: #{result[:errors].join(', ')}"
      )
    else
      Rails.logger.info(
        "Successfully generated #{result[:count]} UUIDs for #{identifier}"
      )
    end
  end
end
