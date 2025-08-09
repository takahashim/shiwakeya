class CreateUserSpreadsheetPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_spreadsheet_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :service_spreadsheet, null: false, foreign_key: true
      t.boolean :can_edit, default: false

      t.timestamps
    end

    add_index :user_spreadsheet_permissions, [:user_id, :service_spreadsheet_id], 
              unique: true, name: 'index_user_spreadsheet_permissions_unique'
  end
end
