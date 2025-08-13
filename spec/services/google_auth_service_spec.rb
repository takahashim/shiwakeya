require 'rails_helper'
require 'webmock/rspec'

RSpec.describe GoogleAuthService do
  # Generate a valid RSA private key for testing
  let(:private_key) do
    OpenSSL::PKey::RSA.new(2048)
  end

  let(:service_account_json) do
    {
      type: "service_account",
      project_id: "test-project",
      private_key_id: "key-id",
      private_key: private_key.to_pem,
      client_email: "test@test-project.iam.gserviceaccount.com",
      client_id: "123456789",
      auth_uri: "https://accounts.google.com/o/oauth2/auth",
      token_uri: "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url: "https://www.googleapis.com/robot/v1/metadata/x509/test%40test-project.iam.gserviceaccount.com"
    }.to_json
  end

  let(:access_token) { "test-access-token-12345" }

  before do
    # Set up environment variable for GoogleSheetsClient
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GOOGLE_SERVICE_ACCOUNT_JSON").and_return(service_account_json)

    # Mock the OAuth token request (both v4 and v2 endpoints that Google Auth might use)
    stub_request(:post, "https://oauth2.googleapis.com/token")
      .with(
        body: hash_including({
          "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer"
        })
      )
      .to_return(
        status: 200,
        body: {
          access_token: access_token,
          token_type: "Bearer",
          expires_in: 3600
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Also stub the v4 endpoint
    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .with(
        body: hash_including({
          "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer"
        })
      )
      .to_return(
        status: 200,
        body: {
          access_token: access_token,
          token_type: "Bearer",
          expires_in: 3600
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  after(:each) do
    # Clear caches
    described_class.reset_authorization!
    GoogleSheetsClient.reset_client
  end

  describe '.authorization' do
    it 'returns authorization from GoogleSheetsClient' do
      authorization = described_class.authorization

      expect(authorization).not_to be_nil
      expect(authorization).to respond_to(:fetch_access_token!)
    end

    it 'returns a valid Google Auth object' do
      authorization = described_class.authorization

      # The authorization should be a Google Auth credential object
      expect(authorization.class.name).to include('Google::Auth')
    end

    it 'caches the authorization' do
      # First call - should make HTTP request
      first_result = described_class.authorization

      # Reset the GoogleSheetsClient to ensure it would create a new one if called
      GoogleSheetsClient.reset_client

      # Second call should use cached value and NOT make another HTTP request
      # We can verify this by not expecting another OAuth request
      second_result = described_class.authorization

      expect(first_result).to eq(second_result)

      # Either endpoint should have been called only once total
      oauth2_calls = a_request(:post, "https://oauth2.googleapis.com/token")
      v4_calls = a_request(:post, "https://www.googleapis.com/oauth2/v4/token")

      # Check that exactly one of them was called once
      total_calls = 0
      total_calls += 1 if WebMock::RequestRegistry.instance.times_executed(oauth2_calls) == 1
      total_calls += 1 if WebMock::RequestRegistry.instance.times_executed(v4_calls) == 1

      expect(total_calls).to eq(1)
    end
  end

  describe '.reset_authorization!' do
    it 'clears the cached authorization' do
      # First call caches the authorization
      first_auth = described_class.authorization
      expect(first_auth).not_to be_nil

      # Reset both caches
      described_class.reset_authorization!
      GoogleSheetsClient.reset_client

      # Mock a different token for the second request
      stub_request(:post, "https://oauth2.googleapis.com/token")
        .to_return(
          status: 200,
          body: {
            access_token: "different-token-67890",
            token_type: "Bearer",
            expires_in: 3600
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
        .to_return(
          status: 200,
          body: {
            access_token: "different-token-67890",
            token_type: "Bearer",
            expires_in: 3600
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      # Next call should create a new authorization
      second_auth = described_class.authorization

      expect(second_auth).not_to be_nil
      expect(second_auth).not_to eq(first_auth)

      # Should have made 2 OAuth requests total (could be either endpoint)
      oauth2_calls = a_request(:post, "https://oauth2.googleapis.com/token")
      v4_calls = a_request(:post, "https://www.googleapis.com/oauth2/v4/token")

      total_calls = WebMock::RequestRegistry.instance.times_executed(oauth2_calls) +
                    WebMock::RequestRegistry.instance.times_executed(v4_calls)

      expect(total_calls).to eq(2)
    end
  end
end
