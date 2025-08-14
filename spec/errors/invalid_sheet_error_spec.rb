require 'rails_helper'

RSpec.describe InvalidSheetError do
  describe '#initialize' do
    context 'with sheet containing validation errors' do
      let(:spreadsheet) { create(:spreadsheet, name: "Test Spreadsheet") }
      let(:sheet) { create(:sheet, sheet_name: "Sheet1", spreadsheet: spreadsheet) }

      subject do
        allow(spreadsheet).to receive(:fetch_sheet_data).and_return([ [ "ID", "Name" ] ])
        begin
          sheet.sync_rows
        rescue InvalidSheetError => e
          e
        end
      end

      it 'creates error with sheet' do
        expect(subject.sheet).to eq(sheet)
      end

      it 'includes sheet and spreadsheet names in message' do
        expect(subject.message).to include("Sheet 'Sheet1' in 'Test Spreadsheet'")
      end

      it 'includes validation errors in message' do
        expect(subject.message).to include("Validation errors:")
        expect(subject.message).to include("A列のヘッダーは'UUID'である必要があります")
      end
    end

    context 'with sheet without names' do
      let(:sheet) { build(:sheet, sheet_name: nil, spreadsheet: nil) }

      subject do
        sheet.errors.add(:base, "A列のヘッダーは'UUID'である必要があります")
        described_class.new(sheet)
      end

      it 'still includes validation errors' do
        expect(subject.message).to include("Validation errors:")
      end

      it 'does not include sheet name' do
        expect(subject.message).to include("Validation errors:")
        expect(subject.message).not_to include("Sheet '")
      end
    end

    context 'with nil sheet data' do
      subject { described_class.new(nil) }

      it 'creates error with default message' do
        expect(subject.message).to eq("Invalid sheet data")
      end

      it 'has nil sheet' do
        expect(subject.sheet).to be_nil
      end
    end

    context 'with sheet without errors' do
      let(:spreadsheet) { create(:spreadsheet) }
      let(:sheet) do
        create(:sheet, sheet_name: "Sheet1", spreadsheet: spreadsheet)
      end

      subject { described_class.new(sheet) }

      it 'includes sheet name and spreadsheet' do
        expect(subject.message).to include("Sheet 'Sheet1'")
        expect(subject.message).to include(spreadsheet.name)
      end
    end
  end
end
