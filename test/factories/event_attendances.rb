FactoryBot.define do
  factory :event_attendance do
    user
    event
    intention { "Yes" }

    trait :no do
      intention { "No" }
    end
  end
end
