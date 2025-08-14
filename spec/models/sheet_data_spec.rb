require 'rails_helper'

RSpec.describe SheetData, type: :model do
  describe '#initialize' do
    context 'with valid data' do
      let(:raw_data) do
        [
          [ "UUID", "Name", "Amount" ],
          [ "123e4567-e89b-12d3-a456-426614174000", "Item 1", "100" ],
          [ "223e4567-e89b-12d3-a456-426614174001", "Item 2", "200" ]
        ]
      end

      subject { described_class.new(raw_data, sheet_name: "Sheet1", spreadsheet_name: "Test") }

      it 'sets headers correctly' do
        expect(subject.headers).to eq([ "UUID", "Name", "Amount" ])
      end

      it 'sets rows correctly' do
        expect(subject.rows.count).to eq(2)
        expect(subject.rows.first).to eq([ "123e4567-e89b-12d3-a456-426614174000", "Item 1", "100" ])
      end
    end

    context 'with empty data' do
      subject { described_class.new([]) }

      it 'sets empty headers and rows' do
        expect(subject.headers).to eq([])
        expect(subject.rows).to eq([])
      end
    end

    context 'with nil data' do
      subject { described_class.new(nil) }

      it 'sets empty headers and rows' do
        expect(subject.headers).to eq([])
        expect(subject.rows).to eq([])
      end
    end
  end

  describe 'validations' do
    context 'with valid UUID header' do
      let(:sheet_data) do
        described_class.new([ [ "UUID", "Name" ], [ "123", "Item" ] ])
      end

      it 'is valid' do
        expect(sheet_data).to be_valid
      end
    end

    context 'with invalid header in column A' do
      let(:sheet_data) do
        described_class.new([ [ "ID", "Name" ], [ "123", "Item" ] ])
      end

      it 'is not valid' do
        expect(sheet_data).not_to be_valid
      end

      it 'has the correct error message' do
        sheet_data.valid?
        expect(sheet_data.errors[:headers]).to include(
          "A列のヘッダーは'UUID'である必要があります（現在: 'ID'）"
        )
      end
    end

    context 'with Japanese header' do
      let(:sheet_data) do
        described_class.new([ [ "識別子", "名前" ], [ "123", "アイテム" ] ])
      end

      it 'is not valid' do
        expect(sheet_data).not_to be_valid
      end

      it 'has the correct error message' do
        sheet_data.valid?
        expect(sheet_data.errors[:headers]).to include(
          "A列のヘッダーは'UUID'である必要があります（現在: '識別子'）"
        )
      end
    end

    context 'with blank headers' do
      let(:sheet_data) { described_class.new([]) }

      it 'is not valid' do
        expect(sheet_data).not_to be_valid
      end

      it 'has presence error' do
        sheet_data.valid?
        expect(sheet_data.errors[:headers]).to include("can't be blank")
      end
    end
  end

  describe '#each_row_with_index' do
    let(:raw_data) do
      [
        [ "UUID", "Name" ],
        [ "123", "Item 1" ],
        [ "456", "Item 2" ]
      ]
    end
    let(:sheet_data) { described_class.new(raw_data) }

    it 'yields each row with 1-based index' do
      results = []
      sheet_data.each_row_with_index do |row, index|
        results << [ row, index ]
      end

      expect(results).to eq([
        [ [ "123", "Item 1" ], 1 ],
        [ [ "456", "Item 2" ], 2 ]
      ])
    end

    it 'returns an enumerator when no block given' do
      expect(sheet_data.each_row_with_index).to be_a(Enumerator)
    end
  end

  describe '#header_row?' do
    context 'with headers' do
      let(:sheet_data) { described_class.new([ [ "UUID", "Name" ] ]) }

      it 'returns true' do
        expect(sheet_data.header_row?).to be true
      end
    end

    context 'without headers' do
      let(:sheet_data) { described_class.new([]) }

      it 'returns false' do
        expect(sheet_data.header_row?).to be false
      end
    end
  end

  describe '#empty?' do
    context 'with data' do
      let(:sheet_data) { described_class.new([ [ "UUID", "Name" ] ]) }

      it 'returns false' do
        expect(sheet_data.empty?).to be false
      end
    end

    context 'without data' do
      let(:sheet_data) { described_class.new([]) }

      it 'returns true' do
        expect(sheet_data.empty?).to be true
      end
    end
  end

  describe '#uuid_for_row' do
    let(:sheet_data) { described_class.new([ [ "UUID", "Name" ] ]) }

    it 'returns the first column value' do
      expect(sheet_data.uuid_for_row([ "123", "Item" ])).to eq("123")
    end

    it 'returns nil for nil row' do
      expect(sheet_data.uuid_for_row(nil)).to be_nil
    end

    it 'returns nil for empty row' do
      expect(sheet_data.uuid_for_row([])).to be_nil
    end
  end

  describe '#missing_uuid_rows' do
    let(:raw_data) do
      [
        [ "UUID", "Name", "Amount" ],
        [ "uuid-1", "Item 1", "100" ],
        [ "", "Item 2", "200" ],
        [ nil, "Item 3", "300" ],
        [ "uuid-4", "Item 4", "400" ],
        [ "", "", "" ],  # Empty row
        [ "", "Item 6", "" ]
      ]
    end
    let(:sheet_data) { described_class.new(raw_data) }

    it 'returns rows with missing UUIDs but with other data' do
      missing = sheet_data.missing_uuid_rows

      expect(missing).to eq([
        { row_number: 3 },  # Row 2 (Item 2)
        { row_number: 4 },  # Row 3 (Item 3)
        { row_number: 7 }   # Row 6 (Item 6)
      ])
    end

    it 'does not include rows with UUID' do
      missing = sheet_data.missing_uuid_rows
      row_numbers = missing.map { |m| m[:row_number] }

      expect(row_numbers).not_to include(2)  # uuid-1
      expect(row_numbers).not_to include(5)  # uuid-4
    end

    it 'does not include completely empty rows' do
      missing = sheet_data.missing_uuid_rows
      row_numbers = missing.map { |m| m[:row_number] }

      expect(row_numbers).not_to include(6)  # Empty row
    end

    context 'with no missing UUIDs' do
      let(:raw_data) do
        [
          [ "UUID", "Name" ],
          [ "uuid-1", "Item 1" ],
          [ "uuid-2", "Item 2" ]
        ]
      end

      it 'returns empty array' do
        expect(sheet_data.missing_uuid_rows).to eq([])
      end
    end

    context 'with all UUIDs missing' do
      let(:raw_data) do
        [
          [ "UUID", "Name" ],
          [ "", "Item 1" ],
          [ nil, "Item 2" ]
        ]
      end

      it 'returns all rows' do
        missing = sheet_data.missing_uuid_rows

        expect(missing).to eq([
          { row_number: 2 },
          { row_number: 3 }
        ])
      end
    end
  end
end
