require 'rails_helper'

RSpec.describe UuidBackfillService do
  let(:spreadsheet) { create(:spreadsheet) }
  let(:service) { described_class.new(spreadsheet) }

  describe '#perform' do
    context 'when spreadsheet was recently edited' do
      before do
        allow(spreadsheet).to receive(:recently_edited?).and_return(true)
      end

      it 'skips processing' do
        expect(spreadsheet).not_to receive(:sheets)
        service.perform
      end
    end

    context 'when spreadsheet was not recently edited' do
      let(:sheet) { create(:sheet, spreadsheet: spreadsheet) }
      let(:client) { instance_double(SpreadsheetClient) }

      before do
        allow(spreadsheet).to receive(:recently_edited?).and_return(false)
        allow(SpreadsheetClient).to receive(:new).and_return(client)
      end

      context 'with invalid sheet headers' do
        let(:invalid_data) {
          [ [ 'ID', 'Name' ], [ '', 'Test' ] ]
        }

        before do
          allow(spreadsheet).to receive(:fetch_sheet_data)
            .with(sheet.sheet_name)
            .and_return(invalid_data)
        end

        it 'skips invalid sheets' do
          expect(client).not_to receive(:batch_update_values)
          service.perform
        end
      end

      context 'with no missing UUIDs' do
        let(:valid_data) {
          [
            [ 'UUID', 'Name' ],
            [ 'uuid-1', 'Test1' ],
            [ 'uuid-2', 'Test2' ]
          ]
        }

        before do
          allow(spreadsheet).to receive(:fetch_sheet_data)
            .with(sheet.sheet_name)
            .and_return(valid_data)
        end

        it 'does not update anything' do
          expect(client).not_to receive(:batch_update_values)
          service.perform
        end
      end

      context 'with missing UUIDs' do
        let(:data_with_missing) {
          [
            [ 'UUID', 'Name' ],
            [ 'uuid-1', 'Test1' ],
            [ '', 'Test2' ],
            [ '', 'Test3' ]
          ]
        }

        before do
          allow(spreadsheet).to receive(:fetch_sheet_data)
            .with(sheet.sheet_name)
            .and_return(data_with_missing)
          allow(client).to receive(:batch_update_values)
        end

        it 'updates missing UUIDs' do
          expect(client).to receive(:batch_update_values).once
          service.perform
        end

        it 'logs found missing UUIDs' do
          expect(Rails.logger).to receive(:info)
            .with(/Found 2 missing UUIDs/)
          service.perform
        end

        context 'with more than BATCH_SIZE missing UUIDs' do
          let(:large_data) {
            [ [ 'UUID', 'Name' ] ] +
            Array.new(25) { |i| [ i < 5 ? "uuid-#{i}" : '', "Test#{i}" ] }
          }

          before do
            allow(spreadsheet).to receive(:fetch_sheet_data)
              .with(sheet.sheet_name)
              .and_return(large_data)
          end

          it 'processes in batches' do
            # 20 missing UUIDs = 2 batches
            expect(client).to receive(:batch_update_values).twice
            service.perform
          end
        end
      end

      context 'when update fails' do
        let(:data_with_missing) {
          [
            [ 'UUID', 'Name' ],
            [ '', 'Test' ]
          ]
        }

        before do
          allow(spreadsheet).to receive(:fetch_sheet_data)
            .with(sheet.sheet_name)
            .and_return(data_with_missing)
          allow(client).to receive(:batch_update_values)
            .and_raise(StandardError.new('API Error'))
        end

        it 'logs error and continues' do
          expect(Rails.logger).to receive(:error)
            .with(/Failed to fill UUIDs.*API Error/)

          expect { service.perform }.not_to raise_error
        end
      end
    end
  end

  describe 'constants' do
    it 'defines BATCH_SIZE' do
      expect(described_class::BATCH_SIZE).to eq(10)
    end
  end
end
