FactoryBot.define do
  factory :synced_row do
    uuid { SecureRandom.uuid }
    spreadsheet
    sheet_name { "Sheet1" }
    row_number { 1 }
    row_data { [] }
    sync_status { :active }
    last_synced_at { Time.current }
  end
end
