class RenameSpreadsheetSyncsToSyncedRows < ActiveRecord::Migration[8.0]
  def change
    rename_table :spreadsheet_syncs, :synced_rows
  end
end
