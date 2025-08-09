module GoogleSheetsStub
  def stub_google_auth
    # Stub Google Auth token request
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(status: 200, body: { access_token: "test_token", expires_in: 3600 }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_google_sheets_client
    mock_service = instance_double(Google::Apis::SheetsV4::SheetsService)
    allow(Google::Apis::SheetsV4::SheetsService).to receive(:new).and_return(mock_service)
    allow(mock_service).to receive(:authorization=)
    mock_service
  end
end

RSpec.configure do |config|
  config.include GoogleSheetsStub
end
