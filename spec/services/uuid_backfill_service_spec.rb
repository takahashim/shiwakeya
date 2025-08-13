require 'rails_helper'

RSpec.describe UuidBackfillService do
  let(:spreadsheet) { create(:spreadsheet) }
  let(:service) { described_class.new(spreadsheet) }

  describe '#perform' do
    context 'when spreadsheet was recently edited' do
      before do
        allow(spreadsheet).to receive(:recently_edited?).and_return(true)
      end

      it 'skips processing and returns empty results' do
        expect(service.perform).to eq([])
      end

      it 'does not process any sheets' do
        create(:sheet, spreadsheet: spreadsheet)
        expect(SpreadsheetSyncService).not_to receive(:new)

        service.perform
      end
    end

    context 'when spreadsheet was not recently edited' do
      let(:sheet1) { create(:sheet, spreadsheet: spreadsheet) }
      let(:sheet2) { create(:sheet, spreadsheet: spreadsheet) }
      let(:sync_service1) { instance_double(SpreadsheetSyncService) }
      let(:sync_service2) { instance_double(SpreadsheetSyncService) }

      before do
        allow(spreadsheet).to receive(:recently_edited?).and_return(false)
      end

      context 'when no UUIDs are missing' do
        before do
          allow(SpreadsheetSyncService).to receive(:new)
            .with(spreadsheet, sheet1.sheet_name)
            .and_return(sync_service1)
          allow(SpreadsheetSyncService).to receive(:new)
            .with(spreadsheet, sheet2.sheet_name)
            .and_return(sync_service2)
          allow(sync_service1).to receive(:detect_missing_uuids).and_return([])
          allow(sync_service2).to receive(:detect_missing_uuids).and_return([])
        end

        it 'returns empty results' do
          expect(service.perform).to eq([])
        end
      end

      context 'when UUIDs are missing' do
        let(:missing_uuids) { Array.new(25) { |i| { row: i + 2 } } }
        let(:backfill_result) { { count: 10, errors: [] } }

        before do
          allow(SpreadsheetSyncService).to receive(:new)
            .with(spreadsheet, sheet1.sheet_name)
            .and_return(sync_service1)
          allow(sync_service1).to receive(:detect_missing_uuids)
            .and_return(missing_uuids)
          allow(sync_service1).to receive(:backfill_uuids)
            .and_return(backfill_result)
        end

        it 'processes missing UUIDs in batches' do
          expect(sync_service1).to receive(:backfill_uuids).exactly(3).times

          service.perform
        end

        it 'returns results for each batch' do
          results = service.perform

          expect(results.length).to eq(3)
          expect(results.first).to include(
            spreadsheet: spreadsheet.name,
            sheet: sheet1.sheet_name,
            batch: 1,
            result: backfill_result
          )
        end

        it 'logs information about missing UUIDs' do
          # Allow other log messages
          allow(Rails.logger).to receive(:info)

          expect(Rails.logger).to receive(:info)
            .with(/Found 25 rows without UUID/)
            .once

          service.perform
        end

        it 'logs batch results' do
          # Allow the "Found X rows" message
          allow(Rails.logger).to receive(:info).with(/Found 25 rows without UUID/)

          # Expect the "Successfully generated" messages for each batch
          expect(Rails.logger).to receive(:info)
            .with(/Successfully generated/)
            .exactly(3).times

          service.perform
        end

        it 'sleeps between batches' do
          expect(service).to receive(:sleep).with(1).twice

          service.perform
        end
      end

      context 'when backfill has errors' do
        let(:missing_uuids) { [ { row: 2 } ] }
        let(:backfill_result) { { count: 0, errors: [ 'Failed to generate UUID' ] } }

        before do
          allow(SpreadsheetSyncService).to receive(:new)
            .with(spreadsheet, sheet1.sheet_name)
            .and_return(sync_service1)
          allow(sync_service1).to receive(:detect_missing_uuids)
            .and_return(missing_uuids)
          allow(sync_service1).to receive(:backfill_uuids)
            .and_return(backfill_result)
        end

        it 'logs errors' do
          expect(Rails.logger).to receive(:error)
            .with(/UUID backfill errors/)

          service.perform
        end

        it 'still returns results' do
          results = service.perform

          expect(results.length).to eq(1)
          expect(results.first[:result][:errors]).to eq([ 'Failed to generate UUID' ])
        end
      end
    end
  end

  describe '#should_skip_backfill?' do
    it 'delegates to spreadsheet.recently_edited?' do
      expect(spreadsheet).to receive(:recently_edited?).and_return(true)

      expect(service.should_skip_backfill?).to be true
    end
  end

  describe 'constants' do
    it 'defines BATCH_SIZE' do
      expect(described_class::BATCH_SIZE).to eq(10)
    end

    it 'defines BATCH_WAIT_TIME' do
      expect(described_class::BATCH_WAIT_TIME).to eq(1)
    end
  end
end
