require "google/apis/sheets_v4"
require "googleauth"
require "json"

class ServiceAccountSheetsService
  attr_reader :service

  def initialize
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = authorize
  rescue StandardError => e
    Rails.logger.error "Failed to initialize ServiceAccountSheetsService: #{e.message}"
    Rails.logger.error "Error details: #{e.inspect}"
    raise
  end

  # スプレッドシートのメタデータを取得
  def get_spreadsheet(spreadsheet_id)
    @service.get_spreadsheet(spreadsheet_id)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error getting spreadsheet #{spreadsheet_id}: #{e.message}"
    Rails.logger.error "Error details: #{e.inspect}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected error getting spreadsheet #{spreadsheet_id}: #{e.message}"
    Rails.logger.error "Error details: #{e.inspect}"
    nil
  end

  # シートの値を取得
  def get_values(range, spreadsheet_id)
    result = @service.get_spreadsheet_values(spreadsheet_id, range)
    result.values || []
  rescue Google::Apis::Error => e
    Rails.logger.error "Error getting values: #{e.message}"
    []
  end

  # シートに値を書き込み
  def update_values(range, values, spreadsheet_id)
    value_range = Google::Apis::SheetsV4::ValueRange.new
    value_range.values = values
    value_range.range = range

    @service.update_spreadsheet_value(
      spreadsheet_id,
      range,
      value_range,
      value_input_option: "USER_ENTERED"
    )
  rescue Google::Apis::Error => e
    Rails.logger.error "Error updating values: #{e.message}"
    nil
  end

  # 複数のシートに値を書き込み（バッチ更新）
  def batch_update_values(data, spreadsheet_id)
    batch_update_request = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new
    batch_update_request.value_input_option = "USER_ENTERED"
    batch_update_request.data = data.map do |item|
      value_range = Google::Apis::SheetsV4::ValueRange.new
      value_range.range = item[:range]
      value_range.values = item[:values]
      value_range
    end

    @service.batch_update_spreadsheet_value(spreadsheet_id, batch_update_request)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error batch updating values: #{e.message}"
    nil
  end

  # 新しいシートを追加
  def add_sheet(sheet_name, spreadsheet_id)
    batch_update_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new
    batch_update_request.requests = [
      {
        add_sheet: {
          properties: {
            title: sheet_name
          }
        }
      }
    ]

    @service.batch_update_spreadsheet(spreadsheet_id, batch_update_request)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error adding sheet: #{e.message}"
    nil
  end

  # シートをクリア
  def clear_values(range, spreadsheet_id)
    @service.clear_values(spreadsheet_id, range)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error clearing values: #{e.message}"
    nil
  end

  # 値を追加（既存データの下に追加）
  def append_values(range, values, spreadsheet_id)
    value_range = Google::Apis::SheetsV4::ValueRange.new
    value_range.values = values

    @service.append_spreadsheet_value(
      spreadsheet_id,
      range,
      value_range,
      value_input_option: "USER_ENTERED"
    )
  rescue Google::Apis::Error => e
    Rails.logger.error "Error appending values: #{e.message}"
    nil
  end

  private

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
