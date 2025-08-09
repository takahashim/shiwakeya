require 'rails_helper'

RSpec.describe Sheet, type: :model do
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

  describe '#parsed_data' do
    context 'when data is present' do
      let(:sheet) { create(:sheet, data: '[["Header1", "Header2"], ["Value1", "Value2"]]') }

      it 'returns parsed JSON data' do
        expect(sheet.parsed_data).to eq([ [ "Header1", "Header2" ], [ "Value1", "Value2" ] ])
      end
    end

    context 'when data is nil' do
      let(:sheet) { create(:sheet, data: nil) }

      it 'returns empty array' do
        expect(sheet.parsed_data).to eq([])
      end
    end

    context 'when data is invalid JSON' do
      let(:sheet) { create(:sheet, data: 'invalid json') }

      it 'returns empty array' do
        expect(sheet.parsed_data).to eq([])
      end
    end
  end

  describe '#sync_data' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }
    let(:mock_values) { [ [ "Header1", "Header2" ], [ "Value1", "Value2" ] ] }

    before do
      allow(spreadsheet).to receive(:fetch_sheet_data).and_return(mock_values)
    end

    it 'updates data and last_synced_at' do
      freeze_time do
        result = sheet.sync_data

        sheet.reload
        expect(sheet.data).to eq(mock_values.to_json)
        expect(sheet.last_synced_at).to eq(Time.current)
        expect(result).to eq(mock_values)
      end
    end

    context 'when error occurs' do
      before do
        allow(spreadsheet).to receive(:fetch_sheet_data).and_raise(StandardError.new('API Error'))
      end

      it 'logs error and raises' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        expect { sheet.sync_data }.to raise_error(StandardError, 'API Error')
      end
    end
  end

  describe '#clear_local_data' do
    let(:sheet) { create(:sheet, :with_data) }

    it 'clears data and last_synced_at' do
      result = sheet.clear_local_data

      sheet.reload
      expect(sheet.data).to be_nil
      expect(sheet.last_synced_at).to be_nil
      expect(result).to be_truthy
    end
  end

  describe '#write_data' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }
    let(:values) { [ [ "New1", "New2" ], [ "Value1", "Value2" ] ] }

    context 'when write is successful' do
      before do
        allow(spreadsheet).to receive(:update_sheet_data).and_return(true)
      end

      it 'writes data and updates local storage' do
        freeze_time do
          result = sheet.write_data(values)

          expect(result).to be true
          sheet.reload
          expect(sheet.data).to eq(values.to_json)
          expect(sheet.last_synced_at).to eq(Time.current)
        end
      end
    end

    context 'when write fails' do
      before do
        allow(spreadsheet).to receive(:update_sheet_data).and_return(false)
      end

      it 'returns false and does not update local storage' do
        original_data = sheet.data
        original_sync_time = sheet.last_synced_at

        result = sheet.write_data(values)

        expect(result).to be false
        sheet.reload
        expect(sheet.data).to eq(original_data)
        expect(sheet.last_synced_at).to eq(original_sync_time)
      end
    end
  end

  describe '#append_row' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet, sheet_name: 'Test Sheet') }
    let(:mock_client) { instance_double(GoogleSheetsClient) }
    let(:row_data) { [ "New Value 1", "New Value 2" ] }

    before do
      allow(GoogleSheetsClient).to receive(:new).and_return(mock_client)
    end

    context 'when append is successful' do
      before do
        allow(mock_client).to receive(:append_values).and_return(true)
      end

      it 'appends row to Google Sheets' do
        expect(mock_client).to receive(:append_values).with(
          "'Test Sheet'!A:Z",
          [ row_data ],
          spreadsheet.spreadsheet_id
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
          [ row_data ],
          spreadsheet.spreadsheet_id
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
