FactoryBot.define do
  factory :user_block do
    sequence(:reason) { |n| "User Block #{n}" }
    ends_at { Time.now.utc + 1.day }

    user
    creator :factory => :moderator_user

    trait :needs_view do
      needs_view { true }
    end

    trait :expired do
      created_at { Time.now.utc - 2.days }
      ends_at { Time.now.utc - 1.day }
    end

    trait :revoked do
      expired
      revoker :factory => :moderator_user
    end
  end
end
