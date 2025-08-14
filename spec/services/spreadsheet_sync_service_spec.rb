require 'rails_helper'

RSpec.describe SpreadsheetSyncService do
  let(:spreadsheet) { create(:spreadsheet) }
  let(:sheet_name) { "Sheet1" }
  let(:service) { described_class.new(spreadsheet, sheet_name) }

  describe '#sync_data' do
    context 'when headers are valid' do
      let(:valid_sheet_data) do
        [
          [ "UUID", "Name", "Amount" ],
          [ "123e4567-e89b-12d3-a456-426614174000", "Item 1", "100" ],
          [ "223e4567-e89b-12d3-a456-426614174001", "Item 2", "200" ]
        ]
      end

      before do
        allow(spreadsheet).to receive(:fetch_sheet_data).and_return(valid_sheet_data)
      end

      it 'processes data without raising error' do
        expect { service.sync_data }.not_to raise_error
      end

      it 'returns sync results' do
        result = service.sync_data
        expect(result).to have_key(:synced)
        expect(result).to have_key(:skipped)
        expect(result).to have_key(:errors)
      end
    end

    context 'when A column header is not UUID' do
      let(:invalid_sheet_data) do
        [
          [ "ID", "Name", "Amount" ],  # A列が"ID"になっている
          [ "123", "Item 1", "100" ]
        ]
      end

      before do
        allow(spreadsheet).to receive(:fetch_sheet_data).and_return(invalid_sheet_data)
      end

      it 'raises InvalidSheetDataError' do
        expect { service.sync_data }.to raise_error(InvalidSheetDataError) do |error|
          expect(error.sheet_data).to be_a(SheetData)
          expect(error.sheet_data.errors[:headers]).to include(
            "A列のヘッダーは'UUID'である必要があります（現在: 'ID'）"
          )
        end
      end
    end

    context 'when sheet data is empty' do
      before do
        allow(spreadsheet).to receive(:fetch_sheet_data).and_return([])
      end

      it 'raises InvalidSheetDataError due to missing headers' do
        expect { service.sync_data }.to raise_error(InvalidSheetDataError) do |error|
          expect(error.sheet_data).to be_a(SheetData)
          expect(error.sheet_data.errors[:headers]).to include("can't be blank")
        end
      end
    end
  end
end
