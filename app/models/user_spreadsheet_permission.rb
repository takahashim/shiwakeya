class UserSpreadsheetPermission < ApplicationRecord
  belongs_to :user
  belongs_to :spreadsheet

  validates :user_id, uniqueness: { scope: :spreadsheet_id }
end
