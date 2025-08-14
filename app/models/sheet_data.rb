class SheetData
  include ActiveModel::Model
  include ActiveModel::Validations

  REQUIRED_HEADER_COLUMN_A = "UUID".freeze

  attr_accessor :headers, :rows, :sheet_name, :spreadsheet_name

  validates :headers, presence: true
  validate :validate_uuid_column

  def initialize(raw_data, sheet_name: nil, spreadsheet_name: nil)
    @sheet_name = sheet_name
    @spreadsheet_name = spreadsheet_name

    if raw_data.present? && raw_data.is_a?(Array)
      @headers = raw_data.first
      @rows = raw_data[1..] || []
    else
      @headers = []
      @rows = []
    end
  end

  def each_row_with_index
    return enum_for(:each_row_with_index) unless block_given?

    rows.each_with_index do |row, index|
      yield row, index + 1  # 1-based index (header is row 0)
    end
  end

  def header_row?
    headers.present?
  end

  def empty?
    headers.blank? && rows.blank?
  end

  def uuid_column_index
    0  # A列は常にインデックス0
  end

  def uuid_for_row(row)
    row[uuid_column_index] if row.present?
  end

  # UUID欠落行を検出
  def missing_uuid_rows
    each_row_with_index.filter_map do |row, row_number|
      if uuid_for_row(row).blank? && row[1..].any?(&:present?)
        { row_number: row_number + 1 }  # +1 for header row
      end
    end
  end

  private

  def validate_uuid_column
    return if headers.blank?

    if headers[uuid_column_index] != REQUIRED_HEADER_COLUMN_A
      errors.add(:headers,
        "A列のヘッダーは'#{REQUIRED_HEADER_COLUMN_A}'である必要があります（現在: '#{headers[uuid_column_index]}'）")
    end
  end
end
