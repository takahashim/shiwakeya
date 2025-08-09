class ServiceSpreadsheets::SyncsController < ApplicationController
  before_action :require_login
  before_action :set_service_spreadsheet
  before_action :check_spreadsheet_access_permission
  before_action :check_spreadsheet_edit_access

  def create
    @service_spreadsheet.sync_sheets
    redirect_to @service_spreadsheet, notice: "シート情報を同期しました"
  rescue => e
    redirect_to @service_spreadsheet, alert: "同期中にエラーが発生しました: #{e.message}"
  end

  private

  def set_service_spreadsheet
    @service_spreadsheet = ServiceSpreadsheet.find(params[:service_spreadsheet_id])
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@service_spreadsheet)
  end

  def check_spreadsheet_edit_access
    check_spreadsheet_edit_permission(@service_spreadsheet)
  end
end
