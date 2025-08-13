require "google/apis/sheets_v4"
require "googleauth"
require "json"

# Google Sheets APIの低レベルクライアント
class GoogleSheetsClient
  attr_reader :authorization, :service

  def initialize
    @authorization = authorize
    @service = create_service
  end

  # シングルトンのクライアントインスタンスを返す
  def self.client
    @client ||= new
  rescue StandardError => e
    Rails.logger.error "Failed to initialize GoogleSheetsClient: #{e.message}"
    Rails.logger.error "Error details: #{e.inspect}"
    raise
  end

  # 便利メソッド：直接サービスを取得
  def self.service
    client.service
  end

  # テスト用：シングルトンをリセット
  def self.reset_client
    @client = nil
  end

  private

  def create_service
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = @authorization
    service
  end

  def authorize
    # 環境変数からサービスアカウントのJSON認証情報を取得
    service_account_json = ENV["GOOGLE_SERVICE_ACCOUNT_JSON"]

    if service_account_json.blank?
      raise "GOOGLE_SERVICE_ACCOUNT_JSON environment variable is not set"
    end

    # JSON文字列をパース
    service_account_key = JSON.parse(service_account_json)

    # サービスアカウント認証
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(service_account_key.to_json),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )

    authorizer.fetch_access_token!
    authorizer
  end
end
