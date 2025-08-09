FactoryBot.define do
  factory :spreadsheet do
    sequence(:name) { |n| "Spreadsheet #{n}" }
    sequence(:spreadsheet_id) { |n| "spreadsheet_#{n}_#{SecureRandom.hex(8)}" }
    description { Faker::Lorem.sentence }
    is_active { true }

    trait :inactive do
      is_active { false }
    end

    trait :with_sheets do
      after(:create) do |spreadsheet|
        create_list(:sheet, 3, spreadsheet: spreadsheet)
      end
    end
  end
end
