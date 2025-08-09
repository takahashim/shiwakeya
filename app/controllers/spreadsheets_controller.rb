class SpreadsheetsController < ApplicationController
  before_action :require_login
  before_action :require_admin, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_spreadsheet, only: [ :show, :edit, :update, :destroy ]
  before_action :check_spreadsheet_access_permission, only: [ :show ]

  def index
    @spreadsheets = current_user.accessible_spreadsheets
  end

  def show
    @sheets = @spreadsheet.sheets
  end

  def new
    @spreadsheet = Spreadsheet.new
  end

  def create
    @spreadsheet = Spreadsheet.new(spreadsheet_params)

    # スプレッドシートの存在確認
    service = GoogleSheetsClient.new

    begin
      spreadsheet = service.get_spreadsheet(@spreadsheet.spreadsheet_id)

      # 名前が入力されていない場合は、スプレッドシートのタイトルを使用
      if @spreadsheet.name.blank?
        @spreadsheet.name = spreadsheet.properties.title
      end

      if @spreadsheet.save
        @spreadsheet.sync_sheets
        redirect_to @spreadsheet, notice: "スプレッドシートを登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    rescue Google::Apis::ClientError => e
      # より詳細なエラーメッセージ
      flash.now[:alert] = "指定されたスプレッドシートIDが見つかりません。\n" \
                         "以下を確認してください：\n" \
                         "1. スプレッドシートIDが正しいか\n" \
                         "2. サービスアカウントにスプレッドシートが共有されているか\n" \
                         "3. Google Sheets APIが有効になっているか"
      Rails.logger.error "Failed to find spreadsheet with ID: #{@spreadsheet.spreadsheet_id}"
      Rails.logger.error "Error: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @spreadsheet.update(spreadsheet_params)
      redirect_to @spreadsheet, notice: "スプレッドシートを更新しました"
    else
      render :edit
    end
  end

  def destroy
    @spreadsheet.destroy
    redirect_to spreadsheets_path, notice: "スプレッドシートを削除しました"
  end

  private

  def set_spreadsheet
    @spreadsheet = Spreadsheet.find(params[:id])
  end

  def spreadsheet_params
    params.require(:spreadsheet).permit(:name, :spreadsheet_id, :description, :is_active)
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@spreadsheet)
  end
end
