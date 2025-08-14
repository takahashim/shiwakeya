require 'rails_helper'

RSpec.describe SyncedRow, type: :model do
  let(:spreadsheet) { create(:spreadsheet) }

  describe '#should_update?' do
    let(:new_data) { [ 'uuid-1', 'New Name', 'Value' ] }

    context 'for new record' do
      let(:sync) { SyncedRow.new(uuid: 'uuid-1', spreadsheet: spreadsheet, sheet_name: 'Sheet1', row_number: 1) }

      it 'returns true' do
        expect(sync.should_update?(new_data)).to be true
      end
    end

    context 'for existing record with changed data' do
      let(:sync) do
        SyncedRow.create!(
          uuid: 'uuid-1',
          spreadsheet: spreadsheet,
          sheet_name: 'Sheet1',
          row_number: 1,
          row_data: [ 'uuid-1', 'Old Name', 'Value' ]
        )
      end

      it 'returns true' do
        expect(sync.should_update?(new_data)).to be true
      end
    end

    context 'for existing record with same data' do
      let(:sync) do
        SyncedRow.create!(
          uuid: 'uuid-1',
          spreadsheet: spreadsheet,
          sheet_name: 'Sheet1',
          row_number: 1,
          row_data: new_data
        )
      end

      it 'returns false' do
        expect(sync.should_update?(new_data)).to be false
      end
    end
  end

  describe '#mark_as_deleted!' do
    let(:sync) do
      SyncedRow.create!(
        uuid: 'uuid-1',
        spreadsheet: spreadsheet,
        sheet_name: 'Sheet1',
        row_number: 1,
        sync_status: :active
      )
    end

    it 'marks the record as deleted' do
      sync.mark_as_deleted!
      expect(sync.reload.sync_status).to eq('deleted')
    end
  end

  describe '.mark_missing_as_deleted' do
    let!(:sync1) do
      SyncedRow.create!(
        uuid: 'uuid-1',
        spreadsheet: spreadsheet,
        sheet_name: 'Sheet1',
        row_number: 1,
        sync_status: :active
      )
    end

    let!(:sync2) do
      SyncedRow.create!(
        uuid: 'uuid-2',
        spreadsheet: spreadsheet,
        sheet_name: 'Sheet1',
        row_number: 2,
        sync_status: :active
      )
    end

    let!(:sync3) do
      SyncedRow.create!(
        uuid: 'uuid-3',
        spreadsheet: spreadsheet,
        sheet_name: 'Sheet1',
        row_number: 3,
        sync_status: :active
      )
    end

    it 'marks records not in existing_uuids as deleted' do
      existing_uuids = [ 'uuid-1', 'uuid-3' ]

      SyncedRow.mark_missing_as_deleted(spreadsheet.id, 'Sheet1', existing_uuids)

      expect(sync1.reload.sync_status).to eq('active')
      expect(sync2.reload.sync_status).to eq('deleted')
      expect(sync3.reload.sync_status).to eq('active')
    end
  end
end
