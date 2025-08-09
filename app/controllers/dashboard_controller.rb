class DashboardController < ApplicationController
  before_action :require_login

  def index
    @service_spreadsheets = ServiceSpreadsheet.active
    @recent_sheets = ServiceSheet.recently_synced.limit(10)
  end
end
