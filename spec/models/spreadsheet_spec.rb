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

  describe '.for_sync' do
    let!(:active_spreadsheet) { create(:spreadsheet, is_active: true) }
    let!(:inactive_spreadsheet) { create(:spreadsheet, is_active: false) }

    context 'when id is not provided' do
      it 'returns only active spreadsheets' do
        result = Spreadsheet.for_sync
        expect(result).to include(active_spreadsheet)
        expect(result).not_to include(inactive_spreadsheet)
      end
    end

    context 'when id is provided' do
      it 'returns the specific spreadsheet regardless of active status' do
        result = Spreadsheet.for_sync(id: inactive_spreadsheet.id)
        expect(result).to include(inactive_spreadsheet)
        expect(result).not_to include(active_spreadsheet)
      end

      it 'returns empty relation when id does not exist' do
        result = Spreadsheet.for_sync(id: 999999)
        expect(result).to be_empty
      end
    end
  end

  describe '#recently_edited?' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:drive_service) { instance_double(DriveService) }

    before do
      allow(DriveService).to receive(:new).and_return(drive_service)
    end

    context 'when file was modified recently' do
      before do
        allow(drive_service).to receive(:get_last_modified_time)
          .with(spreadsheet.spreadsheet_id)
          .and_return(2.minutes.ago)
      end

      it 'returns true' do
        expect(spreadsheet.recently_edited?).to be true
      end
    end

    context 'when file was not modified recently' do
      before do
        allow(drive_service).to receive(:get_last_modified_time)
          .with(spreadsheet.spreadsheet_id)
          .and_return(10.minutes.ago)
      end

      it 'returns false' do
        expect(spreadsheet.recently_edited?).to be false
      end
    end

    context 'when custom threshold is provided' do
      before do
        allow(drive_service).to receive(:get_last_modified_time)
          .with(spreadsheet.spreadsheet_id)
          .and_return(7.minutes.ago)
      end

      it 'uses the custom threshold' do
        expect(spreadsheet.recently_edited?(threshold: 10.minutes)).to be true
        expect(spreadsheet.recently_edited?(threshold: 5.minutes)).to be false
      end
    end

    context 'when API call fails' do
      before do
        allow(drive_service).to receive(:get_last_modified_time)
          .with(spreadsheet.spreadsheet_id)
          .and_raise(StandardError, 'API Error')
      end

      it 'returns true for safety' do
        expect(spreadsheet.recently_edited?).to be true
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Failed to check sheet activity/)
        spreadsheet.recently_edited?
      end
    end
  end

  describe '#last_modified_time' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:drive_service) { instance_double(DriveService) }
    let(:modified_time) { 1.hour.ago }

    before do
      allow(DriveService).to receive(:new).and_return(drive_service)
      allow(drive_service).to receive(:get_last_modified_time)
        .with(spreadsheet.spreadsheet_id)
        .and_return(modified_time)
    end

    it 'returns the last modified time as Time object' do
      result = spreadsheet.last_modified_time
      expect(result).to be_a(Time)
      expect(result.to_i).to eq(modified_time.to_i)
    end
  end

  describe '#sync_spreadsheet' do
    let(:spreadsheet) { create(:spreadsheet) }
    let(:mock_client) { instance_double(SpreadsheetClient) }
    let(:mock_google_spreadsheet) { double('Google::Apis::SheetsV4::Spreadsheet') }
    let(:mock_sheet) { double('Sheet', properties: double(title: 'Sheet1', sheet_id: 123)) }

    before do
      allow(SpreadsheetClient).to receive(:new).with(spreadsheet.spreadsheet_id).and_return(mock_client)
      allow(mock_client).to receive(:spreadsheet).and_return(mock_google_spreadsheet)
      allow(mock_google_spreadsheet).to receive(:sheets).and_return([ mock_sheet ])
    end

    it 'creates new sheets from Google Sheets' do
      expect { spreadsheet.sync_spreadsheet }.to change { spreadsheet.sheets.count }.by(1)
      expect(spreadsheet.sheets.last.sheet_name).to eq('Sheet1')
    end

    context 'when sheet already exists' do
      before do
        spreadsheet.sheets.create!(sheet_name: 'Sheet1')
      end

      it 'does not create duplicate sheets' do
        expect { spreadsheet.sync_spreadsheet }.not_to change { spreadsheet.sheets.count }
      end
    end
  end
end
