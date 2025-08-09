class SessionsController < ApplicationController
  def new
    # ログインフォーム表示
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "ログインしました"
    else
      # 新規ユーザーとして作成
      email = params[:email]&.downcase
      # 環境変数のADMIN_EMAILと一致する場合は管理者として作成
      role = (email == ENV["ADMIN_EMAIL"]) ? "admin" : "member"

      user = User.create!(
        email: email,
        name: email.split("@")&.first,
        role: role
      )
      session[:user_id] = user.id

      if role == "admin"
        redirect_to root_path, notice: "管理者アカウントを作成してログインしました"
      else
        redirect_to root_path, notice: "アカウントを作成してログインしました"
      end
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "ログアウトしました"
  end
end
