require "google/apis/sheets_v4"
require "google/apis/drive_v3"
require "googleauth"

class GoogleSheetsService
  attr_reader :user, :sheets_service, :drive_service

  def initialize(user)
    @user = user
    @sheets_service = Google::Apis::SheetsV4::SheetsService.new
    @drive_service = Google::Apis::DriveV3::DriveService.new
    authorize!
  end

  def list_spreadsheets
    @drive_service.list_files(
      q: "mimeType='application/vnd.google-apps.spreadsheet'",
      fields: "files(id, name, created_time, modified_time)",
      page_size: 100
    ).files
  rescue Google::Apis::Error => e
    Rails.logger.error "Error listing spreadsheets: #{e.message}"
    []
  end

  def get_spreadsheet(spreadsheet_id)
    @sheets_service.get_spreadsheet(spreadsheet_id)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error getting spreadsheet: #{e.message}"
    nil
  end

  def get_sheet_data(spreadsheet_id, range)
    result = @sheets_service.get_spreadsheet_values(spreadsheet_id, range)
    result.values || []
  rescue Google::Apis::Error => e
    Rails.logger.error "Error getting sheet data: #{e.message}"
    []
  end

  def get_sheet_names(spreadsheet_id)
    spreadsheet = get_spreadsheet(spreadsheet_id)
    return [] unless spreadsheet

    spreadsheet.sheets.map { |sheet| sheet.properties.title }
  rescue Google::Apis::Error => e
    Rails.logger.error "Error getting sheet names: #{e.message}"
    []
  end

  private

  def authorize!
    # トークンが期限切れの場合は更新
    @user.refresh_token! if @user.token_expired?

    # アクセストークンで認証
    authorization = Google::Auth::UserRefreshCredentials.new(
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      access_token: @user.google_access_token,
      refresh_token: @user.google_refresh_token,
      scope: [
        Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY,
        Google::Apis::DriveV3::AUTH_DRIVE_READONLY
      ]
    )

    @sheets_service.authorization = authorization
    @drive_service.authorization = authorization
  end
end
