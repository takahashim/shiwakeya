class User < ApplicationRecord
  has_many :user_spreadsheet_permissions, dependent: :destroy
  has_many :permitted_spreadsheets, through: :user_spreadsheet_permissions, source: :spreadsheet

  validates :email, presence: true, uniqueness: true

  # roleをenumで定義（Rails 7.1以降の新しい書き方）
  enum :role, {
    member: 0,
    accountant: 1,
    admin: 2
  }, prefix: true

  # スプレッドシートへのアクセス権限を確認（アクセス可能＝編集可能）
  def can_access_spreadsheet?(spreadsheet)
    return true if role_admin? || role_accountant?
    return false unless spreadsheet

    user_spreadsheet_permissions.exists?(spreadsheet: spreadsheet)
  end

  # アクセス可能なスプレッドシート一覧を取得
  def accessible_spreadsheets
    if role_admin? || role_accountant?
      Spreadsheet.all
    else
      permitted_spreadsheets
    end
  end
end
