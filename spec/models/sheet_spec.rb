require 'rails_helper'

RSpec.describe Sheet, type: :model do
  describe '#missing_uuid_rows' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }

    before do
      raw_data = [
        [ "UUID", "Name" ],
        [ "uuid-1", "Item 1" ],
        [ "", "Item 2" ],
        [ nil, "Item 3" ],
        [ "uuid-4", "Item 4" ]
      ]
      allow(spreadsheet).to receive(:fetch_sheet_data).and_return(raw_data)
    end

    it 'returns rows missing UUID' do
      missing = sheet.missing_uuid_rows
      expect(missing).to eq([
        { row_number: 3 },  # "Item 2" at row 3
        { row_number: 4 }   # "Item 3" at row 4
      ])
    end
  end
  describe '.recently_synced' do
    let!(:recent_sheet) { create(:sheet, last_synced_at: 1.hour.ago) }
    let!(:old_sheet) { create(:sheet, last_synced_at: 1.week.ago) }
    let!(:never_synced_sheet) { create(:sheet, last_synced_at: nil) }

    it 'returns sheets ordered by last_synced_at desc' do
      results = Sheet.recently_synced
      expect(results.first).to eq(recent_sheet)
      expect(results.second).to eq(old_sheet)
      # NULLは最後になるとは限らないので、存在確認のみ
      expect(results).to include(never_synced_sheet)
    end
  end

  describe '#rows_data' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }

    context 'when synced_rows exist' do
      let!(:row1) { create(:synced_row, spreadsheet: spreadsheet, sheet_name: sheet.sheet_name, row_number: 1, row_data: '["Value1", "Value2"]') }
      let!(:row2) { create(:synced_row, spreadsheet: spreadsheet, sheet_name: sheet.sheet_name, row_number: 2, row_data: '["Value3", "Value4"]') }

      it 'returns parsed row data in order' do
        expect(sheet.rows_data).to eq([
          [ "Value1", "Value2" ],
          [ "Value3", "Value4" ]
        ])
      end
    end

    context 'when no synced_rows exist' do
      it 'returns empty array' do
        expect(sheet.rows_data).to eq([])
      end
    end

    context 'when synced_rows have deleted status' do
      let!(:active_row) { create(:synced_row, spreadsheet: spreadsheet, sheet_name: sheet.sheet_name, row_number: 1, row_data: '["Active"]', sync_status: :active) }
      let!(:deleted_row) { create(:synced_row, spreadsheet: spreadsheet, sheet_name: sheet.sheet_name, row_number: 2, row_data: '["Deleted"]', sync_status: :deleted) }

      it 'returns only active rows' do
        expect(sheet.rows_data).to eq([ [ "Active" ] ])
      end
    end
  end

  describe '#sync_rows' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }
    let(:mock_values) { [ [ "UUID", "Header2" ], [ "uuid-1", "Value2" ] ] }

    before do
      allow(spreadsheet).to receive(:fetch_sheet_data).and_return(mock_values)
    end

    it 'creates synced_rows and updates last_synced_at' do
      freeze_time do
        result = sheet.sync_rows

        expect(result[:synced]).to eq(1)
        expect(result[:skipped]).to eq(0)
        expect(result[:errors]).to be_empty

        sheet.reload
        expect(sheet.last_synced_at).to eq(Time.current)

        synced_row = spreadsheet.synced_rows.first
        expect(synced_row.uuid).to eq("uuid-1")
        expect(synced_row.row_data).to eq([ "uuid-1", "Value2" ])
      end
    end

    context 'when validation fails' do
      let(:mock_values) { [ [ "ID", "Header2" ], [ "uuid-1", "Value2" ] ] }

      it 'raises InvalidSheetError' do
        expect { sheet.sync_rows }.to raise_error(InvalidSheetError)
      end
    end

    context 'when error occurs' do
      before do
        allow(spreadsheet).to receive(:fetch_sheet_data).and_raise(StandardError.new('API Error'))
      end

      it 'logs error and raises' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        expect { sheet.sync_rows }.to raise_error(StandardError, 'API Error')
      end
    end
  end

  describe '#clear_local_data' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet, last_synced_at: 1.hour.ago) }
    let!(:synced_row) { create(:synced_row, spreadsheet: spreadsheet, sheet_name: sheet.sheet_name) }

    it 'deletes synced_rows and clears last_synced_at' do
      expect { sheet.clear_local_data }.to change { spreadsheet.synced_rows.count }.by(-1)

      sheet.reload
      expect(sheet.last_synced_at).to be_nil
    end
  end

  describe '#write_data' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }
    let(:values) { [ [ "UUID", "New2" ], [ "uuid-1", "Value2" ] ] }

    context 'when write is successful' do
      before do
        allow(spreadsheet).to receive(:update_sheet_data).and_return(true)
      end

      before do
        allow(spreadsheet).to receive(:fetch_sheet_data).and_return(values)
      end

      it 'writes data and syncs rows' do
        result = sheet.write_data(values)

        expect(result).to be_truthy
        expect(spreadsheet.synced_rows.count).to eq(1)
        synced_row = spreadsheet.synced_rows.first
        expect(synced_row.uuid).to eq("uuid-1")
      end
    end

    context 'when write fails' do
      before do
        allow(spreadsheet).to receive(:update_sheet_data).and_return(false)
      end

      it 'returns false and does not sync' do
        result = sheet.write_data(values)

        expect(result).to be false
        expect(spreadsheet.synced_rows.count).to eq(0)
      end
    end
  end

  describe '#append_row' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet, sheet_name: 'Test Sheet') }
    let(:mock_client) { instance_double(SpreadsheetClient) }
    let(:row_data) { [ "New Value 1", "New Value 2" ] }

    before do
      allow(SpreadsheetClient).to receive(:new).with(spreadsheet.spreadsheet_id).and_return(mock_client)
    end

    context 'when append is successful' do
      before do
        allow(mock_client).to receive(:append_values).and_return(true)
      end

      it 'appends row to Google Sheets' do
        expect(mock_client).to receive(:append_values).with(
          "'Test Sheet'!A:Z",
          [ row_data ]
        )

        result = sheet.append_row(row_data)
        expect(result).to be_truthy
      end
    end

    context 'when sheet name has no special characters' do
      let(:sheet) { create(:sheet, spreadsheet: spreadsheet, sheet_name: 'SimpleSheet') }

      before do
        allow(mock_client).to receive(:append_values).and_return(true)
      end

      it 'does not escape sheet name' do
        expect(mock_client).to receive(:append_values).with(
          "SimpleSheet!A:Z",
          [ row_data ]
        )

        sheet.append_row(row_data)
      end
    end

    context 'when append fails' do
      before do
        allow(mock_client).to receive(:append_values).and_return(nil)
      end

      it 'returns nil' do
        result = sheet.append_row(row_data)
        expect(result).to be_nil
      end
    end
  end
end
