require 'rails_helper'
require 'webmock/rspec'

RSpec.describe GoogleSheetsClient do
  let(:spreadsheet_id) { 'test_spreadsheet_id' }
  let(:mock_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }
  let(:mock_authorizer) { instance_double(Google::Auth::ServiceAccountCredentials) }

  before do
    # Google認証のモック
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(mock_authorizer)
    allow(mock_authorizer).to receive(:fetch_access_token!)

    # SheetsServiceのモック
    allow(Google::Apis::SheetsV4::SheetsService).to receive(:new).and_return(mock_service)
    allow(mock_service).to receive(:authorization=)
  end

  describe '#get_spreadsheet' do
    let(:client) { described_class.new }
    let(:mock_spreadsheet) { double('Spreadsheet', properties: double(title: 'Test Sheet'), sheets: []) }

    context 'when successful' do
      before do
        allow(mock_service).to receive(:get_spreadsheet).and_return(mock_spreadsheet)
      end

      it 'returns the spreadsheet' do
        result = client.get_spreadsheet(spreadsheet_id)
        expect(result).to eq(mock_spreadsheet)
      end
    end

    context 'when error occurs' do
      before do
        allow(mock_service).to receive(:get_spreadsheet).and_raise(Google::Apis::ClientError.new('Not found'))
      end

      it 'returns nil and logs error' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        result = client.get_spreadsheet(spreadsheet_id)
        expect(result).to be_nil
      end
    end
  end

  describe '#get_values' do
    let(:client) { described_class.new }
    let(:range) { 'Sheet1!A:Z' }
    let(:mock_response) { double('ValueRange', values: [ [ 'A1', 'B1' ], [ 'A2', 'B2' ] ]) }

    context 'when successful' do
      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_return(mock_response)
      end

      it 'returns the values' do
        result = client.get_values(range, spreadsheet_id)
        expect(result).to eq([ [ 'A1', 'B1' ], [ 'A2', 'B2' ] ])
      end
    end

    context 'when sheet is empty' do
      let(:empty_response) { double('ValueRange', values: nil) }

      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_return(empty_response)
      end

      it 'returns empty array' do
        result = client.get_values(range, spreadsheet_id)
        expect(result).to eq([])
      end
    end

    context 'when error occurs' do
      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_raise(Google::Apis::ClientError.new('API Error'))
      end

      it 'logs error and returns empty array' do
        expect(Rails.logger).to receive(:error).with(/Error getting values/)
        result = client.get_values(range, spreadsheet_id)
        expect(result).to eq([])
      end
    end
  end

  describe '#update_values' do
    let(:client) { described_class.new }
    let(:range) { 'Sheet1!A:Z' }
    let(:values) { [ [ 'New1', 'New2' ], [ 'Value1', 'Value2' ] ] }
    let(:mock_response) { double('UpdateValuesResponse') }

    context 'when successful' do
      before do
        allow(mock_service).to receive(:update_spreadsheet_value).and_return(mock_response)
      end

      it 'updates values' do
        expect(mock_service).to receive(:update_spreadsheet_value).with(
          spreadsheet_id,
          range,
          an_instance_of(Google::Apis::SheetsV4::ValueRange),
          value_input_option: 'USER_ENTERED'
        )

        result = client.update_values(range, values, spreadsheet_id)
        expect(result).to eq(mock_response)
      end
    end

    context 'when error occurs' do
      before do
        allow(mock_service).to receive(:update_spreadsheet_value).and_raise(Google::Apis::ClientError.new('API Error'))
      end

      it 'logs error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Error updating values/)
        result = client.update_values(range, values, spreadsheet_id)
        expect(result).to be_nil
      end
    end
  end

  describe '#append_values' do
    let(:client) { described_class.new }
    let(:range) { 'Sheet1!A:Z' }
    let(:values) { [ [ 'Value1', 'Value2' ] ] }
    let(:mock_response) { double('AppendValuesResponse') }

    context 'when successful' do
      before do
        allow(mock_service).to receive(:append_spreadsheet_value).and_return(mock_response)
      end

      it 'appends values' do
        expect(mock_service).to receive(:append_spreadsheet_value).with(
          spreadsheet_id,
          range,
          an_instance_of(Google::Apis::SheetsV4::ValueRange),
          value_input_option: 'USER_ENTERED'
        )

        result = client.append_values(range, values, spreadsheet_id)
        expect(result).to eq(mock_response)
      end
    end

    context 'when error occurs' do
      before do
        allow(mock_service).to receive(:append_spreadsheet_value).and_raise(Google::Apis::ClientError.new('API Error'))
      end

      it 'logs error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Error appending values/)
        result = client.append_values(range, values, spreadsheet_id)
        expect(result).to be_nil
      end
    end
  end

  describe '#clear_values' do
    let(:client) { described_class.new }
    let(:range) { 'Sheet1!A:Z' }
    let(:mock_response) { double('ClearValuesResponse') }

    context 'when successful' do
      before do
        allow(mock_service).to receive(:clear_values).and_return(mock_response)
      end

      it 'clears the values' do
        expect(mock_service).to receive(:clear_values).with(spreadsheet_id, range)
        result = client.clear_values(range, spreadsheet_id)
        expect(result).to eq(mock_response)
      end
    end

    context 'when error occurs' do
      before do
        allow(mock_service).to receive(:clear_values).and_raise(Google::Apis::ClientError.new('API Error'))
      end

      it 'logs error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Error clearing values/)
        result = client.clear_values(range, spreadsheet_id)
        expect(result).to be_nil
      end
    end
  end

  describe '#add_sheet' do
    let(:client) { described_class.new }
    let(:sheet_name) { 'NewSheet' }
    let(:mock_response) { double('BatchUpdateResponse') }

    context 'when successful' do
      before do
        allow(mock_service).to receive(:batch_update_spreadsheet).and_return(mock_response)
      end

      it 'adds a new sheet' do
        expect(mock_service).to receive(:batch_update_spreadsheet).with(
          spreadsheet_id,
          an_instance_of(Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest)
        )

        result = client.add_sheet(sheet_name, spreadsheet_id)
        expect(result).to eq(mock_response)
      end
    end

    context 'when error occurs' do
      before do
        allow(mock_service).to receive(:batch_update_spreadsheet).and_raise(Google::Apis::ClientError.new('API Error'))
      end

      it 'logs error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Error adding sheet/)
        result = client.add_sheet(sheet_name, spreadsheet_id)
        expect(result).to be_nil
      end
    end
  end
end
