class RemoveDataFromSheets < ActiveRecord::Migration[8.0]
  def change
    remove_column :sheets, :data, :text
  end
end
