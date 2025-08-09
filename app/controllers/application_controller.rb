class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :admin?, :accountant?, :member?

  # 共通エラーハンドリング（特定のエラーから順に、StandardErrorは最後に）
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from JSON::ParserError, with: :handle_json_parse_error
  rescue_from Google::Apis::Error, with: :handle_google_api_error if defined?(Google::Apis::Error)
  rescue_from StandardError, with: :handle_standard_error

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

  # エラーハンドリングメソッド
  def handle_standard_error(exception)
    Rails.logger.error "StandardError: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n") if Rails.env.development?

    respond_to do |format|
      format.html {
        redirect_back(fallback_location: root_path, alert: "エラーが発生しました: #{exception.message}")
      }
      format.json {
        render json: { error: exception.message }, status: :internal_server_error
      }
    end
  end

  def handle_record_not_found(exception)
    Rails.logger.warn "RecordNotFound: #{exception.message}"

    respond_to do |format|
      format.html {
        redirect_to root_path, alert: "指定されたデータが見つかりません"
      }
      format.json {
        render json: { error: "レコードが見つかりません" }, status: :not_found
      }
    end
  end

  def handle_parameter_missing(exception)
    Rails.logger.warn "ParameterMissing: #{exception.message}"

    respond_to do |format|
      format.html {
        redirect_back(fallback_location: root_path, alert: "必要なパラメータが不足しています")
      }
      format.json {
        render json: { error: "必要なパラメータが不足しています: #{exception.param}" }, status: :bad_request
      }
    end
  end

  def handle_record_invalid(exception)
    Rails.logger.warn "RecordInvalid: #{exception.message}"

    respond_to do |format|
      format.html {
        redirect_back(fallback_location: root_path, alert: "データの保存に失敗しました: #{exception.record.errors.full_messages.join(', ')}")
      }
      format.json {
        render json: { error: exception.record.errors }, status: :unprocessable_entity
      }
    end
  end

  def handle_json_parse_error(exception)
    Rails.logger.warn "JSON ParseError: #{exception.message}"

    respond_to do |format|
      format.html {
        redirect_back(fallback_location: root_path, alert: "データの形式が正しくありません")
      }
      format.json {
        render json: { error: "無効なJSON形式です" }, status: :bad_request
      }
    end
  end

  def handle_google_api_error(exception)
    Rails.logger.error "Google API Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n") if Rails.env.development?

    error_message = case exception.status_code
    when 403
      "Google APIへのアクセスが拒否されました。権限を確認してください。"
    when 404
      "指定されたGoogleスプレッドシートが見つかりません。"
    when 429
      "APIリクエストの制限に達しました。しばらく待ってから再試行してください。"
    else
      "Google APIエラーが発生しました: #{exception.message}"
    end

    respond_to do |format|
      format.html {
        redirect_back(fallback_location: root_path, alert: error_message)
      }
      format.json {
        render json: { error: error_message }, status: :service_unavailable
      }
    end
  end
end
