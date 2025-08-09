FactoryBot.define do
  factory :sheet do
    spreadsheet
    sequence(:sheet_name) { |n| "Sheet #{n}" }
    purpose { %w[input output reference].sample }
    last_synced_at { nil }
    data { nil }

    trait :with_data do
      data { [ [ "Header1", "Header2" ], [ "Data1", "Data2" ] ].to_json }
      last_synced_at { Time.current }
    end

    trait :input do
      purpose { "input" }
    end

    trait :output do
      purpose { "output" }
    end

    trait :reference do
      purpose { "reference" }
    end
  end
end
