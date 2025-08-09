class ServiceSheetsController < ApplicationController
  before_action :require_login
  before_action :set_service_spreadsheet
  before_action :check_spreadsheet_access_permission
  before_action :set_service_sheet, only: [ :show, :sync, :update, :clear, :append ]
  before_action :check_spreadsheet_edit_access, only: [ :sync, :update, :clear, :append ]

  def show
    @data = @service_sheet.parsed_data
  end

  def sync
    @service_sheet.sync_data
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                notice: "データを同期しました"
  rescue => e
    Rails.logger.error "Sync error for sheet #{@service_sheet.sheet_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                alert: "同期中にエラーが発生しました: #{e.message}\n\nシート名: #{@service_sheet.sheet_name}"
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
  rescue JSON::ParserError
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                alert: "データの形式が正しくありません"
  rescue => e
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                alert: "エラーが発生しました: #{e.message}"
  end

  def append
    # 新しい行を追加
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
  rescue => e
    redirect_to service_spreadsheet_service_sheet_path(@service_spreadsheet, @service_sheet),
                alert: "エラーが発生しました: #{e.message}"
  end

  def clear
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
    @service_sheet = @service_spreadsheet.service_sheets.find(params[:id])
  end

  def check_spreadsheet_access_permission
    check_spreadsheet_access(@service_spreadsheet)
  end

  def check_spreadsheet_edit_access
    check_spreadsheet_edit_permission(@service_spreadsheet)
  end
end
