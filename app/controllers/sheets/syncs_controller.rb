class Sheets::SyncsController < ApplicationController
  before_action :require_login
  before_action :set_spreadsheet
  before_action :set_sheet
  before_action :check_spreadsheet_access_permission

  def create
    @sheet.sync_data
    redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                notice: "データを同期しました"
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
