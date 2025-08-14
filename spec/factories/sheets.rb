FactoryBot.define do
  factory :sheet do
    spreadsheet
    sequence(:sheet_name) { |n| "Sheet #{n}" }
    purpose { %w[input output reference].sample }
    last_synced_at { nil }

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
