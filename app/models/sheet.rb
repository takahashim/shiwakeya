class Sheet < ApplicationRecord
  belongs_to :spreadsheet

  validates :sheet_name, presence: true

  scope :by_purpose, ->(purpose) { where(purpose: purpose) }
  scope :recently_synced, -> { order(last_synced_at: :desc) }

  # SheetDataオブジェクトとして取得
  def as_sheet_data
    raw_data = spreadsheet.fetch_sheet_data(sheet_name)
    SheetData.new(raw_data, sheet_name: sheet_name, spreadsheet_name: spreadsheet.name)
  end

  def sync_data
    values = spreadsheet.fetch_sheet_data(sheet_name)

    update!(
      data: values.to_json,
      last_synced_at: Time.current
    )

    values
  rescue => e
    Rails.logger.error "Error syncing sheet data for #{sheet_name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def parsed_data
    return [] unless data.present?
    JSON.parse(data)
  rescue JSON::ParserError
    []
  end

  def write_data(values)
    result = spreadsheet.update_sheet_data(sheet_name, values)

    if result
      update!(
        data: values.to_json,
        last_synced_at: Time.current
      )
    end

    result
  end

  def append_row(row_data)
    client = SpreadsheetClient.new(spreadsheet.spreadsheet_id)
    # シート名に特殊文字が含まれる場合はシングルクォートでエスケープ
    escaped_sheet_name = sheet_name.include?(" ") || sheet_name.include?("!") ? "'#{sheet_name.gsub("'", "''")}'" : sheet_name
    range = "#{escaped_sheet_name}!A:Z"
    client.append_values(range, [ row_data ])
  end

  # ローカルのデータベースに保存されているデータをクリア（スプレッドシートのデータは削除しない）
  def clear_local_data
    update!(
      data: nil,
      last_synced_at: nil
    )
  end
end
