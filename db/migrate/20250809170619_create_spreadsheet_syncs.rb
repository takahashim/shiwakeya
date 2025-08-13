class CreateSpreadsheetSyncs < ActiveRecord::Migration[8.0]
  def change
    create_table :spreadsheet_syncs do |t|
      t.string :uuid, null: false
      t.integer :spreadsheet_id, null: false
      t.string :sheet_name
      t.integer :row_number
      t.text :row_data
      t.integer :sync_status, default: 0, null: false
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :spreadsheet_syncs, :uuid, unique: true
    add_index :spreadsheet_syncs, [ :spreadsheet_id, :sheet_name, :row_number ], unique: true
    add_index :spreadsheet_syncs, :sync_status

    add_foreign_key :spreadsheet_syncs, :spreadsheets
  end
end
