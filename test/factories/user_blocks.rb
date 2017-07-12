FactoryGirl.define do
  factory :user_block do
    sequence(:reason) { |n| "User Block #{n}" }
    ends_at Time.now + 1.day

    user
    association :creator, :factory => :moderator_user

    trait :needs_view do
      needs_view true
    end

    trait :expired do
      ends_at Time.now - 1.day
    end

    trait :revoked do
      association :revoker, :factory => :moderator_user
    end
  end
end
