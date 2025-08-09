class Sheets::AppendsController < ApplicationController
  before_action :require_login
  before_action :set_spreadsheet
  before_action :set_sheet
  before_action :check_spreadsheet_access_permission

  def create
    if params[:row_data].present?
      row_data = params[:row_data].values

      if @sheet.append_row(row_data)
        redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                    notice: "行を追加しました"
      else
        redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                    alert: "行の追加に失敗しました"
      end
    else
      redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                  alert: "データが送信されていません"
    end
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
