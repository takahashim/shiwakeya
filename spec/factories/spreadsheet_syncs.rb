FactoryBot.define do
  factory :spreadsheet_sync do
    uuid { "MyString" }
    sheet_id { "MyString" }
    sheet_name { "MyString" }
    row_number { 1 }
    sheet_data { "MyText" }
    local_data { "MyText" }
    sync_status { 1 }
    last_synced_at { "2025-08-10 02:06:19" }
    sheet_modified_at { "2025-08-10 02:06:19" }
    version { 1 }
  end
end
