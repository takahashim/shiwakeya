class UserSpreadsheetPermission < ApplicationRecord
  belongs_to :user
  belongs_to :service_spreadsheet

  validates :user_id, uniqueness: { scope: :service_spreadsheet_id }
end
