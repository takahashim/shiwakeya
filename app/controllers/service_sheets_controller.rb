class ServiceSheetsController < ApplicationController
  before_action :require_login
  before_action :set_service_spreadsheet
  before_action :check_spreadsheet_access_permission
  before_action :set_service_sheet, only: [ :show, :update ]

  def show
    @data = @service_sheet.parsed_data
  end

  def update
    # データの更新（フォームから送信されたデータを書き込み）
    if params[:data].present?
      values = JSON.parse(params[:data])

      if @service_sheet.write_data(values)
        redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                    notice: "データを更新しました"
      else
        redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                    alert: "データの更新に失敗しました"
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
    @service_sheet = @service_spreadsheet.service_sheets.find(params[:id])
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@service_spreadsheet)
  end
end
