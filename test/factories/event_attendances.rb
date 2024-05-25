FactoryBot.define do
  factory :event_attendance do
    user
    event
    intention { "Maybe" }

    trait :no do
      intention { "No" }
    end

    trait :yes do
      intention { "Yes" }
    end
  end
end
