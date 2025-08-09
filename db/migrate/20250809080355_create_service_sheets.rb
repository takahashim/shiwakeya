class CreateServiceSheets < ActiveRecord::Migration[8.0]
  def change
    create_table :service_sheets do |t|
      t.references :service_spreadsheet, null: false, foreign_key: true
      t.string :sheet_name
      t.string :purpose
      t.datetime :last_synced_at
      t.text :data

      t.timestamps
    end
  end
end
