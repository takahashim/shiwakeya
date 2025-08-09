class Sheets::ClearsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_spreadsheet
  before_action :set_sheet
  before_action :check_spreadsheet_access_permission

  def destroy
    if @sheet.clear_local_data
      redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                  notice: "データをクリアしました"
    else
      redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                  alert: "データのクリアに失敗しました"
    end
  rescue => e
    Rails.logger.error "Error clearing local data: #{e.message}"
    redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                alert: "データのクリアに失敗しました: #{e.message}"
  end

  private

  def set_spreadsheet
    @spreadsheet = Spreadsheet.find(params[:spreadsheet_id])
  end

  def set_sheet
    @sheet = @spreadsheet.sheets.find(params[:sheet_id])
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@spreadsheet)
  end
end
