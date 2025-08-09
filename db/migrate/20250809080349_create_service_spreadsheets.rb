class CreateServiceSpreadsheets < ActiveRecord::Migration[8.0]
  def change
    create_table :service_spreadsheets do |t|
      t.string :name, null: false
      t.string :spreadsheet_id, null: false
      t.text :description
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :service_spreadsheets, :spreadsheet_id, unique: true
  end
end
