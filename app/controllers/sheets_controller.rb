class SheetsController < ApplicationController
  before_action :require_login
  before_action :set_spreadsheet
  before_action :check_spreadsheet_access_permission
  before_action :set_sheet, only: [ :show, :update ]

  def show
    @data = @sheet.rows_data
  end

  def update
    # データの更新（フォームから送信されたデータを書き込み）
    if params[:data].present?
      values = JSON.parse(params[:data])

      if @sheet.write_data(values)
        redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                    notice: "データを更新しました"
      else
        redirect_to spreadsheet_sheet_path(@spreadsheet, @sheet),
                    alert: "データの更新に失敗しました"
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
    @sheet = @spreadsheet.sheets.find(params[:id])
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@spreadsheet)
  end
end
