class UserPermissionsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user, only: [ :edit, :update ]

  def index
    @users = User.all.order(:email)
  end

  def edit
    @spreadsheets = ServiceSpreadsheet.all
    @user_permissions = @user.user_spreadsheet_permissions.includes(:service_spreadsheet)
  end

  def update
    if @user.update(user_params)
      update_spreadsheet_permissions
      redirect_to user_permissions_path, notice: "ユーザー権限を更新しました"
    else
      @spreadsheets = ServiceSpreadsheet.all
      @user_permissions = @user.user_spreadsheet_permissions.includes(:service_spreadsheet)
      render :edit
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:role)
  end

  def update_spreadsheet_permissions
    return unless @user.member?

    existing_permissions = @user.user_spreadsheet_permissions.index_by(&:service_spreadsheet_id)

    params[:permissions]&.each do |spreadsheet_id, permission_params|
      next if permission_params[:grant] != "1"

      permission = existing_permissions[spreadsheet_id.to_i] ||
                  @user.user_spreadsheet_permissions.build(service_spreadsheet_id: spreadsheet_id)

      permission.can_edit = permission_params[:can_edit] == "1"
      permission.save
    end

    params[:remove_permissions]&.each do |spreadsheet_id|
      @user.user_spreadsheet_permissions.where(service_spreadsheet_id: spreadsheet_id).destroy_all
    end
  end
end
