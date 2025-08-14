class InvalidSheetDataError < StandardError
  attr_reader :sheet_data

  def initialize(sheet_data)
    @sheet_data = sheet_data
    super(build_message)
  end

  private

  def build_message
    return "Invalid sheet data" if sheet_data.nil?

    messages = []

    if sheet_data.sheet_name.present? && sheet_data.spreadsheet_name.present?
      messages << "Sheet '#{sheet_data.sheet_name}' in '#{sheet_data.spreadsheet_name}'"
    elsif sheet_data.sheet_name.present?
      messages << "Sheet '#{sheet_data.sheet_name}'"
    end

    if sheet_data.errors.any?
      messages << "Validation errors: #{sheet_data.errors.full_messages.join(', ')}"
    end

    messages.join(" - ")
  end
end
