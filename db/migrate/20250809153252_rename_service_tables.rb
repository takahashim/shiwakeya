class RenameServiceTables < ActiveRecord::Migration[8.0]
  def change
    # Rename tables
    rename_table :service_spreadsheets, :spreadsheets
    rename_table :service_sheets, :sheets
    
    # Rename foreign key columns
    rename_column :sheets, :service_spreadsheet_id, :spreadsheet_id
    rename_column :user_spreadsheet_permissions, :service_spreadsheet_id, :spreadsheet_id
    
    # Rename indexes
    rename_index :sheets, "index_service_sheets_on_service_spreadsheet_id", "index_sheets_on_spreadsheet_id"
    rename_index :user_spreadsheet_permissions, "index_user_spreadsheet_permissions_on_service_spreadsheet_id", "index_user_spreadsheet_permissions_on_spreadsheet_id"
  end
end
