require "rails_helper"

RSpec.describe GoogleSheetsClient do
  let(:mock_service_account_json) do
    {
      type: "service_account",
      project_id: "test-project",
      private_key_id: "key-id",
      private_key: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC9W8bA\n-----END PRIVATE KEY-----\n",
      client_email: "test@test-project.iam.gserviceaccount.com",
      client_id: "123456789",
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/test%40test-project.iam.gserviceaccount.com"
    }.to_json
  end

  before do
    # 環境変数をモック - デフォルト値を設定してから特定の値をスタブ
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GOOGLE_SERVICE_ACCOUNT_JSON").and_return(mock_service_account_json)

    # Google認証をモック
    mock_authorizer = instance_double(Google::Auth::ServiceAccountCredentials)
    allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(mock_authorizer)
    allow(mock_authorizer).to receive(:fetch_access_token!)

    # シングルトンをリセット
    described_class.reset_client
  end

  after do
    # テスト後にシングルトンをリセット
    described_class.reset_client
  end

  describe ".client" do
    it "returns a singleton instance" do
      client1 = described_class.client
      client2 = described_class.client
      expect(client1).to be(client2)
    end

    it "has authorization and service attributes" do
      client = described_class.client
      expect(client.authorization).to be_present
      expect(client.service).to be_a(Google::Apis::SheetsV4::SheetsService)
    end

    context "when GOOGLE_SERVICE_ACCOUNT_JSON is not set" do
      before do
        allow(ENV).to receive(:[]).with("GOOGLE_SERVICE_ACCOUNT_JSON").and_return(nil)
      end

      it "raises an error" do
        expect { described_class.client }.to raise_error(RuntimeError, /GOOGLE_SERVICE_ACCOUNT_JSON environment variable is not set/)
      end
    end

    context "when initialization fails" do
      before do
        allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_raise(StandardError, "Auth failed")
      end

      it "logs the error and re-raises" do
        expect(Rails.logger).to receive(:error).with(/Failed to initialize GoogleSheetsClient/)
        expect(Rails.logger).to receive(:error).with(/Error details:/)
        expect { described_class.client }.to raise_error(StandardError, "Auth failed")
      end
    end
  end

  describe ".service" do
    it "returns the service from the singleton client" do
      service = described_class.service
      expect(service).to be_a(Google::Apis::SheetsV4::SheetsService)
      expect(service).to be(described_class.client.service)
    end
  end

  describe "#initialize" do
    it "creates authorization and service" do
      client = described_class.new
      expect(client.authorization).to be_present
      expect(client.service).to be_a(Google::Apis::SheetsV4::SheetsService)
      expect(client.service.authorization).to eq(client.authorization)
    end
  end
end
