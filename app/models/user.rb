class User < ApplicationRecord
  has_many :user_spreadsheet_permissions, dependent: :destroy
  has_many :permitted_spreadsheets, through: :user_spreadsheet_permissions, source: :service_spreadsheet

  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[admin accountant member] }

  def admin?
    role == "admin"
  end

  def accountant?
    role == "accountant"
  end

  def member?
    role == "member"
  end

  # スプレッドシートへのアクセス権限を確認
  def can_access_spreadsheet?(spreadsheet)
    return true if admin? || accountant?
    return false unless spreadsheet

    user_spreadsheet_permissions.exists?(service_spreadsheet: spreadsheet)
  end

  # スプレッドシートの編集権限を確認
  def can_edit_spreadsheet?(spreadsheet)
    return true if admin? || accountant?
    return false unless spreadsheet

    user_spreadsheet_permissions.where(service_spreadsheet: spreadsheet, can_edit: true).exists?
  end

  # アクセス可能なスプレッドシート一覧を取得
  def accessible_spreadsheets
    if admin? || accountant?
      ServiceSpreadsheet.all
    else
      permitted_spreadsheets
    end
  end
end
