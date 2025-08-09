require 'rails_helper'

RSpec.describe Spreadsheet, type: :model do
  describe '.active' do
    let!(:active_spreadsheet) { create(:spreadsheet, is_active: true) }
    let!(:inactive_spreadsheet) { create(:spreadsheet, is_active: false) }

    it 'returns only active spreadsheets' do
      expect(Spreadsheet.active).to include(active_spreadsheet)
      expect(Spreadsheet.active).not_to include(inactive_spreadsheet)
    end
  end

  describe '#sync_sheets' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:mock_client) { instance_double(GoogleSheetsClient) }
    let(:mock_google_spreadsheet) { double('Google::Apis::SheetsV4::Spreadsheet') }
    let(:mock_sheet) { double('Sheet', properties: double(title: 'Sheet1', sheet_id: 123)) }

    before do
      allow(GoogleSheetsClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:get_spreadsheet).and_return(mock_google_spreadsheet)
      allow(mock_google_spreadsheet).to receive(:sheets).and_return([ mock_sheet ])
    end

    it 'creates new sheets from Google Sheets' do
      expect { spreadsheet.sync_sheets }.to change { spreadsheet.sheets.count }.by(1)
      expect(spreadsheet.sheets.last.sheet_name).to eq('Sheet1')
    end

    context 'when sheet already exists' do
      before do
        spreadsheet.sheets.create!(sheet_name: 'Sheet1')
      end

      it 'does not create duplicate sheets' do
        expect { spreadsheet.sync_sheets }.not_to change { spreadsheet.sheets.count }
      end
    end
  end
end
