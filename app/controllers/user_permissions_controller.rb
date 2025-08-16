class UserPermissionsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user, only: [ :edit, :update ]

  def index
    @users = User.all.order(:email)
  end

  def edit
    @spreadsheets = Spreadsheet.all
    @user_permissions = @user.user_spreadsheet_permissions.includes(:spreadsheet)
  end

  def update
    if update_user_role && update_spreadsheet_permissions
      redirect_to user_permissions_path, notice: "ユーザー権限を更新しました"
    else
      @spreadsheets = Spreadsheet.all
      @user_permissions = @user.user_spreadsheet_permissions.includes(:spreadsheet)
      render :edit
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def update_user_role
    # Safely update role without mass assignment vulnerability
    role = params.dig(:user, :role)

    # Only update if role is valid
    if role.present? && User.roles.keys.include?(role)
      @user.role = role
      @user.save
    else
      true # Return true if no role update requested
    end
  end

  def update_spreadsheet_permissions
    return true unless @user.role_member?

    existing_permissions = @user.user_spreadsheet_permissions.index_by(&:spreadsheet_id)

    params[:permissions]&.each do |spreadsheet_id, permission_params|
      next if permission_params[:grant] != "1"

      permission = existing_permissions[spreadsheet_id.to_i] ||
                  @user.user_spreadsheet_permissions.build(spreadsheet_id: spreadsheet_id)

      permission.can_edit = permission_params[:can_edit] == "1"
      permission.save
    end

    params[:remove_permissions]&.each do |spreadsheet_id|
      @user.user_spreadsheet_permissions.where(spreadsheet_id: spreadsheet_id).destroy_all
    end

    true
  end
end
