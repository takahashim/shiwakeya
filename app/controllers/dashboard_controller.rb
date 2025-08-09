class DashboardController < ApplicationController
  before_action :require_login

  def index
    @spreadsheets = Spreadsheet.active
    @recent_sheets = Sheet.recently_synced.limit(10)
  end
end
