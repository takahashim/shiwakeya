class SpreadsheetSyncService
  attr_reader :sheet_id, :sheet_service

  def initialize(sheet_id, sheet_service = nil)
    @sheet_id = sheet_id
    @sheet_service = sheet_service || GoogleSheetsService.new
  end

  def pull_all
    sheet_rows = fetch_sheet_data
    results = { created: 0, updated: 0, skipped: 0, errors: 0 }

    sheet_rows.each_with_index do |row_data, index|
      next if index == 0

      result = pull_row(row_data, index + 1)
      results[result] += 1 if results.key?(result)
    end

    results
  end

  def pull_row(row_data, row_number)
    uuid = extract_uuid(row_data)

    return :skipped if uuid.blank?

    sync_record = SpreadsheetSync.find_or_initialize_by(uuid: uuid)

    if sync_record.new_record?
      sync_record.assign_attributes(
        sheet_id: sheet_id,
        row_number: row_number,
        sheet_data: row_data,
        sync_status: :synced,
        last_synced_at: Time.current,
        sheet_modified_at: Time.current
      )
      sync_record.save!
      :created
    else
      if sheet_data_changed?(sync_record.sheet_data, row_data)
        sync_record.merge_sheet_data(row_data)
        sync_record.mark_synced!
        :updated
      else
        :skipped
      end
    end
  rescue => e
    Rails.logger.error "Sync error for row #{row_number}: #{e.message}"
    :errors
  end

  def assign_uuid_to_row(row_number, uuid = nil)
    uuid ||= Uuidv7Generator.generate
    column_letter = uuid_column_letter
    sheet_service.update_cell(sheet_id, "#{column_letter}#{row_number}", uuid)
    uuid
  end

  def assign_uuids_to_empty_rows
    sheet_rows = fetch_sheet_data
    assigned = []

    sheet_rows.each_with_index do |row_data, index|
      next if index == 0
      row_number = index + 1

      if extract_uuid(row_data).blank?
        uuid = assign_uuid_to_row(row_number)
        assigned << { row: row_number, uuid: uuid }
      end
    end

    assigned
  end

  private

  def fetch_sheet_data
    sheet_service.get_values(sheet_id, "A:Z")
  end

  def extract_uuid(row_data)
    row_data["uuid"] || row_data[uuid_column_index]
  end

  def sheet_data_changed?(old_data, new_data)
    old_data != new_data
  end

  def uuid_column_index
    0
  end

  def uuid_column_letter
    "A"
  end
end
