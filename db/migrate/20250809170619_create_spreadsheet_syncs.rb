class CreateSpreadsheetSyncs < ActiveRecord::Migration[8.0]
  def change
    create_table :spreadsheet_syncs do |t|
      t.string :uuid, null: false
      t.string :sheet_id, null: false
      t.string :sheet_name
      t.integer :row_number
      t.text :sheet_data
      t.text :local_data
      t.integer :sync_status, default: 0, null: false
      t.datetime :last_synced_at
      t.datetime :sheet_modified_at
      t.integer :version, default: 0, null: false

      t.timestamps
    end
    add_index :spreadsheet_syncs, :uuid, unique: true
    add_index :spreadsheet_syncs, :sheet_id
    add_index :spreadsheet_syncs, [:sheet_id, :row_number], unique: true
    add_index :spreadsheet_syncs, :sync_status
  end
end
