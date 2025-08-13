require "rails_helper"

RSpec.describe SpreadsheetClient do
  let(:spreadsheet_id) { "test_spreadsheet_id" }
  let(:client) { described_class.new(spreadsheet_id) }
  let(:mock_service) { instance_double(Google::Apis::SheetsV4::SheetsService) }

  before do
    # GoogleSheetsClient.serviceをモック
    allow(GoogleSheetsClient).to receive(:service).and_return(mock_service)
  end

  describe "#initialize" do
    it "sets the spreadsheet_id" do
      expect(client.spreadsheet_id).to eq(spreadsheet_id)
    end
  end

  describe "#spreadsheet" do
    let(:mock_spreadsheet) { double("Spreadsheet", properties: double(title: "Test Sheet"), sheets: []) }

    context "when successful" do
      before do
        allow(mock_service).to receive(:get_spreadsheet).and_return(mock_spreadsheet)
      end

      it "returns the spreadsheet" do
        result = client.spreadsheet
        expect(result).to eq(mock_spreadsheet)
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:get_spreadsheet).and_raise(Google::Apis::ClientError.new("Not found"))
      end

      it "returns nil and logs error" do
        expect(Rails.logger).to receive(:error).with(/Error getting spreadsheet/)
        result = client.spreadsheet
        expect(result).to be_nil
      end
    end
  end

  describe "#values" do
    let(:range) { "Sheet1!A:Z" }
    let(:mock_response) { double("ValueRange", values: [ [ "A1", "B1" ], [ "A2", "B2" ] ]) }

    context "when successful" do
      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_return(mock_response)
      end

      it "returns the values" do
        result = client.values(range)
        expect(result).to eq([ [ "A1", "B1" ], [ "A2", "B2" ] ])
      end
    end

    context "when sheet is empty" do
      let(:empty_response) { double("ValueRange", values: nil) }

      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_return(empty_response)
      end

      it "returns empty array" do
        result = client.values(range)
        expect(result).to eq([])
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "logs error and returns empty array" do
        expect(Rails.logger).to receive(:error).with(/Error getting values/)
        result = client.values(range)
        expect(result).to eq([])
      end
    end
  end

  describe "#[]" do
    let(:range) { "Sheet1!A:Z" }
    let(:mock_response) { double("ValueRange", values: [ [ "A1", "B1" ], [ "A2", "B2" ] ]) }

    context "when successful" do
      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_return(mock_response)
      end

      it "returns the values using array accessor syntax" do
        result = client[range]
        expect(result).to eq([ [ "A1", "B1" ], [ "A2", "B2" ] ])
      end

      it "behaves the same as values method" do
        expect(client[range]).to eq(client.values(range))
      end
    end

    context "when sheet is empty" do
      let(:empty_response) { double("ValueRange", values: nil) }

      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_return(empty_response)
      end

      it "returns empty array" do
        result = client[range]
        expect(result).to eq([])
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:get_spreadsheet_values).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "logs error and returns empty array" do
        expect(Rails.logger).to receive(:error).with(/Error getting values/)
        result = client[range]
        expect(result).to eq([])
      end

      it "allows safe chaining with array methods" do
        expect(Rails.logger).to receive(:error).with(/Error getting values/)
        result = client[range].map { |row| row.first }
        expect(result).to eq([])
      end
    end
  end

  describe "#update_values" do
    let(:range) { "Sheet1!A1" }
    let(:values) { [ [ "New1", "New2" ], [ "Value1", "Value2" ] ] }
    let(:mock_response) { double("UpdateValuesResponse") }

    context "when successful" do
      before do
        allow(mock_service).to receive(:update_spreadsheet_value).and_return(mock_response)
      end

      it "updates values" do
        expect(mock_service).to receive(:update_spreadsheet_value).with(
          spreadsheet_id,
          range,
          an_instance_of(Google::Apis::SheetsV4::ValueRange),
          value_input_option: "USER_ENTERED"
        )

        result = client.update_values(range, values)
        expect(result).to eq(mock_response)
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:update_spreadsheet_value).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Error updating values/)
        result = client.update_values(range, values)
        expect(result).to be_nil
      end
    end
  end

  describe "#batch_update_values" do
    let(:data) do
      [
        { range: "Sheet1!A1", values: [ [ "A1" ] ] },
        { range: "Sheet1!B1", values: [ [ "B1" ] ] }
      ]
    end
    let(:mock_response) { double("BatchUpdateValuesResponse") }

    context "when successful" do
      before do
        allow(mock_service).to receive(:batch_update_values).and_return(mock_response)
      end

      it "batch updates values" do
        expect(mock_service).to receive(:batch_update_values).with(
          spreadsheet_id,
          an_instance_of(Google::Apis::SheetsV4::BatchUpdateValuesRequest)
        )

        result = client.batch_update_values(data)
        expect(result).to eq(mock_response)
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:batch_update_values).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Error batch updating values/)
        result = client.batch_update_values(data)
        expect(result).to be_nil
      end
    end
  end

  describe "#append_values" do
    let(:range) { "Sheet1!A:Z" }
    let(:values) { [ [ "Value1", "Value2" ] ] }
    let(:mock_response) { double("AppendValuesResponse") }

    context "when successful" do
      before do
        allow(mock_service).to receive(:append_spreadsheet_value).and_return(mock_response)
      end

      it "appends values" do
        expect(mock_service).to receive(:append_spreadsheet_value).with(
          spreadsheet_id,
          range,
          an_instance_of(Google::Apis::SheetsV4::ValueRange),
          value_input_option: "USER_ENTERED"
        )

        result = client.append_values(range, values)
        expect(result).to eq(mock_response)
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:append_spreadsheet_value).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Error appending values/)
        result = client.append_values(range, values)
        expect(result).to be_nil
      end
    end
  end

  describe "#clear_values" do
    let(:range) { "Sheet1!A:Z" }
    let(:mock_response) { double("ClearValuesResponse") }

    context "when successful" do
      before do
        allow(mock_service).to receive(:clear_values).and_return(mock_response)
      end

      it "clears the values" do
        expect(mock_service).to receive(:clear_values).with(spreadsheet_id, range)
        result = client.clear_values(range)
        expect(result).to eq(mock_response)
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:clear_values).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Error clearing values/)
        result = client.clear_values(range)
        expect(result).to be_nil
      end
    end
  end

  describe "#add_sheet" do
    let(:sheet_name) { "NewSheet" }
    let(:mock_response) { double("BatchUpdateResponse") }

    context "when successful" do
      before do
        allow(mock_service).to receive(:batch_update_spreadsheet).and_return(mock_response)
      end

      it "adds a new sheet" do
        expect(mock_service).to receive(:batch_update_spreadsheet).with(
          spreadsheet_id,
          an_instance_of(Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest)
        )

        result = client.add_sheet(sheet_name)
        expect(result).to eq(mock_response)
      end
    end

    context "when error occurs" do
      before do
        allow(mock_service).to receive(:batch_update_spreadsheet).and_raise(Google::Apis::ClientError.new("API Error"))
      end

      it "logs error and returns nil" do
        expect(Rails.logger).to receive(:error).with(/Error adding sheet/)
        result = client.add_sheet(sheet_name)
        expect(result).to be_nil
      end
    end
  end

  describe "#fetch_sheet_data" do
    let(:sheet_name) { "Test Sheet" }
    let(:values) { [ [ "A1", "B1" ], [ "A2", "B2" ] ] }
    let(:mock_response) { double("ValueRange", values: values) }

    before do
      allow(mock_service).to receive(:get_spreadsheet_values).and_return(mock_response)
    end

    it "fetches all data from the sheet" do
      result = client.fetch_sheet_data(sheet_name)
      expect(result).to eq(values)
    end

    context "with special characters in sheet name" do
      let(:sheet_name) { "Sheet with spaces!" }

      it "escapes the sheet name properly" do
        expect(mock_service).to receive(:get_spreadsheet_values).with(
          spreadsheet_id,
          "'Sheet with spaces!'!A:Z"
        )
        client.fetch_sheet_data(sheet_name)
      end
    end
  end

  describe "#update_sheet_data" do
    let(:sheet_name) { "Test Sheet" }
    let(:values) { [ [ "A1", "B1" ], [ "A2", "B2" ] ] }
    let(:mock_response) { double("UpdateValuesResponse") }

    before do
      allow(mock_service).to receive(:update_spreadsheet_value).and_return(mock_response)
    end

    it "updates all data in the sheet" do
      result = client.update_sheet_data(sheet_name, values)
      expect(result).to eq(mock_response)
    end

    context "with special characters in sheet name" do
      let(:sheet_name) { "Sheet with spaces!" }

      it "escapes the sheet name properly" do
        expect(mock_service).to receive(:update_spreadsheet_value).with(
          spreadsheet_id,
          "'Sheet with spaces!'!A1",
          an_instance_of(Google::Apis::SheetsV4::ValueRange),
          value_input_option: "USER_ENTERED"
        )
        client.update_sheet_data(sheet_name, values)
      end
    end
  end

  describe "#authorization" do
    let(:mock_client) { instance_double(GoogleSheetsClient) }
    let(:mock_authorization) { double("Authorization") }

    before do
      allow(GoogleSheetsClient).to receive(:client).and_return(mock_client)
      allow(mock_client).to receive(:authorization).and_return(mock_authorization)
    end

    it "returns authorization from GoogleSheetsClient" do
      expect(client.authorization).to eq(mock_authorization)
    end
  end
end
