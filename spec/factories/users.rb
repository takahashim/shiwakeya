FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    role { :member }

    trait :admin do
      role { :admin }
    end

    trait :accountant do
      role { :accountant }
    end

    trait :member do
      role { :member }
    end
  end
end
