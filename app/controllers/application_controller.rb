class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :admin?, :accountant?, :member?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def admin?
    current_user&.admin?
  end

  def accountant?
    current_user&.accountant?
  end

  def member?
    current_user&.member?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "ログインが必要です"
    end
  end

  def require_admin
    unless admin?
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end

  def require_admin_or_accountant
    unless admin? || accountant?
      redirect_to root_path, alert: "この操作には管理者または会計担当者の権限が必要です"
    end
  end

  def check_spreadsheet_access(spreadsheet)
    unless current_user.can_access_spreadsheet?(spreadsheet)
      redirect_to root_path, alert: "このスプレッドシートへのアクセス権限がありません"
    end
  end

  def check_spreadsheet_edit_permission(spreadsheet)
    unless current_user.can_edit_spreadsheet?(spreadsheet)
      redirect_to root_path, alert: "このスプレッドシートの編集権限がありません"
    end
  end
end
