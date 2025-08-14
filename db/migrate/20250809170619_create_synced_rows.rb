class CreateSyncedRows < ActiveRecord::Migration[8.0]
  def change
    create_table :synced_rows do |t|
      t.string :uuid, null: false
      t.integer :spreadsheet_id, null: false
      t.string :sheet_name
      t.integer :row_number
      t.text :row_data
      t.integer :sync_status, default: 0, null: false
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :synced_rows, :uuid, unique: true
    add_index :synced_rows, [ :spreadsheet_id, :sheet_name, :row_number ], unique: true
    add_index :synced_rows, :sync_status

    add_foreign_key :synced_rows, :spreadsheets
  end
end
