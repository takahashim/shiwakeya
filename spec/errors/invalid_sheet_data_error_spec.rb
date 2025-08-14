require 'rails_helper'

RSpec.describe InvalidSheetDataError do
  describe '#initialize' do
    context 'with valid sheet data containing errors' do
      let(:sheet_data) do
        data = SheetData.new([ [ "ID", "Name" ] ], sheet_name: "Sheet1", spreadsheet_name: "Test Spreadsheet")
        data.valid? # trigger validation
        data
      end

      subject { described_class.new(sheet_data) }

      it 'creates error with sheet data' do
        expect(subject.sheet_data).to eq(sheet_data)
      end

      it 'includes sheet and spreadsheet names in message' do
        expect(subject.message).to include("Sheet 'Sheet1' in 'Test Spreadsheet'")
      end

      it 'includes validation errors in message' do
        expect(subject.message).to include("Validation errors:")
        expect(subject.message).to include("A列のヘッダーは'UUID'である必要があります")
      end
    end

    context 'with sheet data without names' do
      let(:sheet_data) do
        data = SheetData.new([ [ "ID", "Name" ] ])
        data.valid?
        data
      end

      subject { described_class.new(sheet_data) }

      it 'still includes validation errors' do
        expect(subject.message).to include("Validation errors:")
      end

      it 'does not include sheet name' do
        expect(subject.message).not_to include("Sheet '")
      end
    end

    context 'with nil sheet data' do
      subject { described_class.new(nil) }

      it 'creates error with default message' do
        expect(subject.message).to eq("Invalid sheet data")
      end

      it 'has nil sheet_data' do
        expect(subject.sheet_data).to be_nil
      end
    end

    context 'with sheet data without errors' do
      let(:sheet_data) do
        SheetData.new([ [ "UUID", "Name" ] ], sheet_name: "Sheet1")
      end

      subject { described_class.new(sheet_data) }

      it 'includes sheet name only' do
        expect(subject.message).to eq("Sheet 'Sheet1'")
      end
    end
  end
end
