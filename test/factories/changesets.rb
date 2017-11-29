FactoryBot.define do
  factory :changeset do
    created_at Time.now.utc
    closed_at Time.now.utc + 1.day

    user

    trait :closed do
      created_at Time.now.utc - 5.hours
      closed_at Time.now.utc - 4.hours
    end
  end
end
