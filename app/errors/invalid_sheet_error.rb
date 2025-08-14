class InvalidSheetError < StandardError
  attr_reader :sheet

  def initialize(sheet)
    @sheet = sheet
    super(build_message)
  end

  private

  def build_message
    return "Invalid sheet data" if sheet.nil?

    messages = []

    if sheet.sheet_name.present? && sheet.spreadsheet&.name.present?
      messages << "Sheet '#{sheet.sheet_name}' in '#{sheet.spreadsheet.name}'"
    elsif sheet.sheet_name.present?
      messages << "Sheet '#{sheet.sheet_name}'"
    end

    if sheet.errors.any?
      messages << "Validation errors: #{sheet.errors.full_messages.join(', ')}"
    end

    messages.join(" - ")
  end
end
