FactoryBot.define do
  factory :event_attendance do
    user
    event
    intention { "yes" }

    trait :no do
      intention { "no" }
    end
  end
end
