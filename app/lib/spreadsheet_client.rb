# 特定のスプレッドシートに対する操作を行うクライアント
class SpreadsheetClient
  attr_reader :spreadsheet_id

  def initialize(spreadsheet_id)
    @spreadsheet_id = spreadsheet_id
    @service = google_sheets_service
  end

  # スプレッドシートのメタデータを取得
  def spreadsheet
    @service.get_spreadsheet(@spreadsheet_id)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error getting spreadsheet #{@spreadsheet_id}: #{e.message}"
    nil
  end

  # シートの値を取得
  def values(range)
    result = @service.get_spreadsheet_values(@spreadsheet_id, range)
    result.values || []
  rescue Google::Apis::Error => e
    Rails.logger.error "Error getting values from #{@spreadsheet_id}: #{e.message}"
    []
  end

  # 配列アクセサスタイルでの値取得（valuesメソッドのエイリアス）
  # 使用例: client["Sheet1!A1:B10"]
  alias [] values

  # シートに値を書き込み
  def update_values(range, values)
    value_range = Google::Apis::SheetsV4::ValueRange.new(
      range: range,
      values: values
    )

    @service.update_spreadsheet_value(
      @spreadsheet_id,
      range,
      value_range,
      value_input_option: "USER_ENTERED"
    )
  rescue Google::Apis::Error => e
    Rails.logger.error "Error updating values in #{@spreadsheet_id}: #{e.message}"
    nil
  end

  # 複数範囲へのバッチ更新
  def batch_update_values(data)
    batch_update_request = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new
    batch_update_request.value_input_option = "USER_ENTERED"
    batch_update_request.data = data.map do |item|
      Google::Apis::SheetsV4::ValueRange.new(
        range: item[:range],
        values: item[:values]
      )
    end

    @service.batch_update_values(@spreadsheet_id, batch_update_request)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error batch updating values in #{@spreadsheet_id}: #{e.message}"
    nil
  end

  # 値を追加（既存データの下に追加）
  def append_values(range, values)
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: values)

    @service.append_spreadsheet_value(
      @spreadsheet_id,
      range,
      value_range,
      value_input_option: "USER_ENTERED"
    )
  rescue Google::Apis::Error => e
    Rails.logger.error "Error appending values to #{@spreadsheet_id}: #{e.message}"
    nil
  end

  # シートをクリア
  def clear_values(range)
    @service.clear_values(@spreadsheet_id, range)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error clearing values in #{@spreadsheet_id}: #{e.message}"
    nil
  end

  # 新しいシートを追加
  def add_sheet(sheet_name)
    batch_update_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: [
        {
          add_sheet: {
            properties: {
              title: sheet_name
            }
          }
        }
      ]
    )

    @service.batch_update_spreadsheet(@spreadsheet_id, batch_update_request)
  rescue Google::Apis::Error => e
    Rails.logger.error "Error adding sheet to #{@spreadsheet_id}: #{e.message}"
    nil
  end

  # 高レベルメソッド: シートデータ全体を取得
  def fetch_sheet_data(sheet_name)
    range = "#{escape_sheet_name(sheet_name)}!A:Z"
    values(range)
  end

  # 高レベルメソッド: シートデータ全体を更新
  def update_sheet_data(sheet_name, values)
    range = "#{escape_sheet_name(sheet_name)}!A1"
    update_values(range, values)
  end

  # 認証情報を取得（Drive API等で使用）
  def authorization
    GoogleSheetsClient.client.authorization
  end

  private

  def google_sheets_service
    GoogleSheetsClient.service
  end

  def escape_sheet_name(sheet_name)
    sheet_name.include?(" ") || sheet_name.include?("!") ? "'#{sheet_name.gsub("'", "''")}'" : sheet_name
  end
end
