class ServiceSheets::AppendsController < ApplicationController
  before_action :require_login
  before_action :set_service_spreadsheet
  before_action :set_service_sheet
  before_action :check_spreadsheet_access_permission

  def create
    if params[:row_data].present?
      row_data = params[:row_data].values

      if @service_sheet.append_row(row_data)
        redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                    notice: "行を追加しました"
      else
        redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                    alert: "行の追加に失敗しました"
      end
    else
      redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                  alert: "データが送信されていません"
    end
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
end
