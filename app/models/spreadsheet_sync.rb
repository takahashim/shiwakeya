class SpreadsheetSync < ApplicationRecord
  belongs_to :spreadsheet

  # UUIDはスプレッドシートから取得した値を保存（Rails側では生成しない）
  validates :uuid, presence: true, uniqueness: true
  validates :spreadsheet_id, presence: true
  validates :sheet_name, presence: true
  validates :row_number, presence: true

  # ステータスはシンプルに
  enum :sync_status, {
    active: 0,      # 正常に同期中
    deleted: 1,     # スプレッドシートから削除された
    error: 2        # エラー状態
  }


  serialize :row_data, coder: JSON

  scope :active, -> { where(sync_status: :active) }
  scope :by_sheet, ->(spreadsheet_id, sheet_name) {
    where(spreadsheet_id: spreadsheet_id, sheet_name: sheet_name)
  }

  # 同期時のデータ更新
  def update_from_sheet(row_data, row_number)
    update!(
      row_data: row_data,
      row_number: row_number,
      last_synced_at: Time.current,
      sync_status: :active
    )
  end

  # データの比較
  def data_changed?(new_data)
    row_data != new_data
  end
end
