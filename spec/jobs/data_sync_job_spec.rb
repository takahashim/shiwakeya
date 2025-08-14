require 'rails_helper'

RSpec.describe DataSyncJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let(:spreadsheet) { create(:spreadsheet, is_active: true) }
    let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }
    let(:sync_result) { { synced: 5, skipped: 2, errors: [] } }

    context 'when sheet has invalid headers' do
      let!(:sheet1) { create(:sheet, spreadsheet: spreadsheet) }

      before do
        invalid_sheet_data = SheetData.new([ [ "ID", "Name" ] ], sheet_name: sheet1.sheet_name, spreadsheet_name: spreadsheet.name)
        invalid_sheet_data.valid? # trigger validation
        allow_any_instance_of(Spreadsheet).to receive(:sync_sheet).and_raise(
          InvalidSheetDataError.new(invalid_sheet_data)
        )
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        expect(Rails.logger).to receive(:error).with(/Invalid sheet format/)
        expect(Rails.logger).to receive(:error).with(/Sync errors/)

        described_class.new.perform(spreadsheet.id)
      end

      it 'continues processing other sheets' do
        create(:sheet, spreadsheet: spreadsheet, sheet_name: 'Sheet2')

        invalid_sheet_data = SheetData.new([ [ "ID", "Name" ] ], sheet_name: "Sheet1", spreadsheet_name: spreadsheet.name)
        invalid_sheet_data.valid?

        # First sheet raises error, second sheet succeeds
        call_count = 0
        allow_any_instance_of(Spreadsheet).to receive(:sync_sheet) do
          call_count += 1
          if call_count == 1
            raise InvalidSheetDataError.new(invalid_sheet_data)
          else
            sync_result
          end
        end

        expect { described_class.new.perform(spreadsheet.id) }.not_to raise_error
      end
    end

    context 'when no spreadsheet_id is provided' do
      let!(:active_spreadsheet) { create(:spreadsheet, is_active: true) }
      let!(:inactive_spreadsheet) { create(:spreadsheet, is_active: false) }
      let!(:sheet1) { create(:sheet, spreadsheet: active_spreadsheet) }

      it 'processes only active spreadsheets' do
        expect_any_instance_of(Spreadsheet).to receive(:sync_sheet)
          .with(sheet1)
          .and_return(sync_result)

        described_class.new.perform
      end
    end

    context 'when spreadsheet_id is provided' do
      let!(:sheet1) { create(:sheet, spreadsheet: spreadsheet) }

      it 'processes only the specified spreadsheet' do
        expect_any_instance_of(Spreadsheet).to receive(:sync_sheet)
          .with(sheet1)
          .and_return(sync_result)

        described_class.new.perform(spreadsheet.id)
      end
    end

    context 'when sync completes successfully' do
      let!(:sheet1) { create(:sheet, spreadsheet: spreadsheet) }

      before do
        allow_any_instance_of(Spreadsheet).to receive(:sync_sheet).and_return(sync_result)
      end

      it 'logs sync results' do
        allow(Rails.logger).to receive(:info)

        described_class.new.perform(spreadsheet.id)

        expect(Rails.logger).to have_received(:info).with(/Synced/)
      end
    end

    context 'when processing multiple sheets' do
      let!(:sheet1) { create(:sheet, spreadsheet: spreadsheet) }
      let!(:sheet2) { create(:sheet, spreadsheet: spreadsheet) }
      let(:sync_result1) { { synced: 3, skipped: 1, errors: [] } }
      let(:sync_result2) { { synced: 2, skipped: 0, errors: [ 'Error' ] } }

      before do
        results = [ sync_result1, sync_result2 ]
        allow_any_instance_of(Spreadsheet).to receive(:sync_sheet) do
          results.shift
        end
      end

      it 'processes all sheets' do
        expect_any_instance_of(Spreadsheet).to receive(:sync_sheet).twice

        described_class.new.perform(spreadsheet.id)
      end

      it 'logs results for each sheet' do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        described_class.new.perform(spreadsheet.id)

        # First sheet has no errors, should log info
        expect(Rails.logger).to have_received(:info).with(/Synced/).at_least(:once)
        # Second sheet has errors, should log error
        expect(Rails.logger).to have_received(:error).with(/Sync errors/).at_least(:once)
      end
    end
  end

  describe 'job configuration' do
    it 'is queued in default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end
end
