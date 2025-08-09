class Spreadsheets::SyncsController < ApplicationController
  before_action :require_login
  before_action :set_spreadsheet
  before_action :check_spreadsheet_access_permission

  def create
    @spreadsheet.sync_sheets
    redirect_to @spreadsheet, notice: "シート情報を同期しました"
  end

  private

  def set_spreadsheet
    @spreadsheet = Spreadsheet.find(params[:spreadsheet_id])
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@spreadsheet)
  end
end
