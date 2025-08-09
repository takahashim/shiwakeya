class UserSpreadsheetPermission < ApplicationRecord
  belongs_to :user
  belongs_to :service_spreadsheet

  validates :user_id, uniqueness: { scope: :service_spreadsheet_id }

  scope :with_edit_permission, -> { where(can_edit: true) }
end