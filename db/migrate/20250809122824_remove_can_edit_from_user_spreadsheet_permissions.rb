class RemoveCanEditFromUserSpreadsheetPermissions < ActiveRecord::Migration[8.0]
  def change
    remove_column :user_spreadsheet_permissions, :can_edit, :boolean
  end
end
