class ServiceSheets::SyncsController < ApplicationController
  before_action :require_login
  before_action :set_service_spreadsheet
  before_action :set_service_sheet
  before_action :check_spreadsheet_access_permission
  before_action :check_spreadsheet_edit_access

  def create
    @service_sheet.sync_data
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                notice: "データを同期しました"
  rescue => e
    Rails.logger.error "Sync error for sheet #{@service_sheet.sheet_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                alert: "同期中にエラーが発生しました: #{e.message}\n\nシート名: #{@service_sheet.sheet_name}"
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
