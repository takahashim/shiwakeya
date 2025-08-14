class UuidBackfillService
  BATCH_SIZE = 10

  def initialize(spreadsheet)
    @spreadsheet = spreadsheet
  end

  def perform
    return if @spreadsheet.recently_edited?

    @spreadsheet.sheets.each do |sheet|
      fill_missing_uuids(sheet.sheet_name)
    end
  end

  private

  def fill_missing_uuids(sheet_name)
    sheet_data = @spreadsheet.load_sheet_data(sheet_name)
    return unless sheet_data.valid?

    missing = sheet_data.missing_uuid_rows
    return if missing.empty?

    Rails.logger.info "Found #{missing.size} missing UUIDs in #{sheet_name}"

    missing.each_slice(BATCH_SIZE) do |batch|
      update_batch(batch, sheet_name)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to fill UUIDs for #{sheet_name}: #{e.message}"
  end

  def update_batch(rows, sheet_name)
    updates = rows.map do |row|
      {
        range: "#{sheet_name}!A#{row[:row_number]}",
        values: [ [ Uuidv7Generator.generate ] ]
      }
    end

    client = SpreadsheetClient.new(@spreadsheet.spreadsheet_id)
    client.batch_update_values(updates)
  end
end
