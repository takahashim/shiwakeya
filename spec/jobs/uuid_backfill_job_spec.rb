require 'rails_helper'

RSpec.describe UuidBackfillJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:active_spreadsheet) { create(:spreadsheet, is_active: true) }
    let(:inactive_spreadsheet) { create(:spreadsheet, is_active: false) }
    let(:service) { instance_double(UuidBackfillService) }

    before do
      allow(UuidBackfillService).to receive(:new).and_return(service)
    end

    context 'when no spreadsheet_id is provided' do
      let!(:active_spreadsheet2) { create(:spreadsheet, is_active: true) }

      it 'processes all active spreadsheets' do
        allow(service).to receive(:perform)

        described_class.new.perform

        expect(service).to have_received(:perform).at_least(:once)
      end
    end

    context 'when spreadsheet_id is provided' do
      it 'processes only the specified spreadsheet' do
        expect(UuidBackfillService).to receive(:new).with(active_spreadsheet).and_return(service)
        expect(service).to receive(:perform)

        described_class.new.perform(active_spreadsheet.id)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in low_priority queue' do
      expect(described_class.new.queue_name).to eq('low_priority')
    end
  end
end
