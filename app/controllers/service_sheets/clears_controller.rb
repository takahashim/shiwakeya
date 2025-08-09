class ServiceSheets::ClearsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_service_spreadsheet
  before_action :set_service_sheet
  before_action :check_spreadsheet_access_permission
  before_action :check_spreadsheet_edit_access

  def destroy
    if @service_sheet.clear_all_data
      redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                  notice: "データをクリアしました"
    else
      redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                  alert: "データのクリアに失敗しました"
    end
  rescue => e
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                alert: "エラーが発生しました: #{e.message}"
  end

  private

  def set_service_spreadsheet
    @service_spreadsheet = ServiceSpreadsheet.find(params[:service_spreadsheet_id])
  end

  def set_service_sheet
    @service_sheet = @service_spreadsheet.service_sheets.find(params[:service_sheet_id])
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@service_spreadsheet)
  end

  def check_spreadsheet_edit_access
    check_spreadsheet_edit_permission(@service_spreadsheet)
  end
end
