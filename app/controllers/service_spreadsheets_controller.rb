class ServiceSpreadsheetsController < ApplicationController
  before_action :require_login
  before_action :require_admin, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_service_spreadsheet, only: [:show, :edit, :update, :destroy, :sync]
  before_action :check_spreadsheet_access_permission, only: [:show]
  before_action :check_spreadsheet_edit_access, only: [:sync]

  def index
    @service_spreadsheets = current_user.accessible_spreadsheets
  end

  def show
    @service_sheets = @service_spreadsheet.service_sheets
  end

  def new
    @service_spreadsheet = ServiceSpreadsheet.new
  end

  def create
    @service_spreadsheet = ServiceSpreadsheet.new(service_spreadsheet_params)

    begin
      # スプレッドシートの存在確認
      service = ServiceAccountSheetsService.new
      spreadsheet = service.get_spreadsheet(@service_spreadsheet.spreadsheet_id)

      if spreadsheet
        @service_spreadsheet.name ||= spreadsheet.properties.title
        
        if @service_spreadsheet.save
          @service_spreadsheet.sync_sheets
          redirect_to @service_spreadsheet, notice: 'スプレッドシートを登録しました'
        else
          render :new
        end
      else
        # より詳細なエラーメッセージ
        flash.now[:alert] = "指定されたスプレッドシートIDが見つかりません。\n" \
                           "以下を確認してください：\n" \
                           "1. スプレッドシートIDが正しいか\n" \
                           "2. サービスアカウントにスプレッドシートが共有されているか\n" \
                           "3. Google Sheets APIが有効になっているか"
        Rails.logger.error "Failed to find spreadsheet with ID: #{@service_spreadsheet.spreadsheet_id}"
        render :new
      end
    rescue => e
      Rails.logger.error "Error in create action: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash.now[:alert] = "エラーが発生しました: #{e.message}"
      render :new
    end
  end

  def edit
  end

  def update
    if @service_spreadsheet.update(service_spreadsheet_params)
      redirect_to @service_spreadsheet, notice: 'スプレッドシートを更新しました'
    else
      render :edit
    end
  end

  def destroy
    @service_spreadsheet.destroy
    redirect_to service_spreadsheets_path, notice: 'スプレッドシートを削除しました'
  end

  def sync
    @service_spreadsheet.sync_sheets
    redirect_to @service_spreadsheet, notice: 'シート情報を同期しました'
  rescue => e
    redirect_to @service_spreadsheet, alert: "同期中にエラーが発生しました: #{e.message}"
  end

  private

  def set_service_spreadsheet
    @service_spreadsheet = ServiceSpreadsheet.find(params[:id])
  end

  def service_spreadsheet_params
    params.require(:service_spreadsheet).permit(:name, :spreadsheet_id, :description, :is_active)
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@service_spreadsheet)
  end

  def check_spreadsheet_edit_access
    check_spreadsheet_edit_permission(@service_spreadsheet)
  end
end