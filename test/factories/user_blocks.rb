FactoryGirl.define do
  factory :user_block do
    sequence(:reason) { |n| "User Block #{n}" }
    ends_at Time.now + 1.day

    # FIXME: requires User factory
    user_id 13

    # FIXME: requires User factory
    creator_id 15

    trait :needs_view do
      needs_view true
    end

    trait :expired do
      ends_at Time.now - 1.day
    end

    trait :revoked do
      # FIXME: requires User factory
      revoker_id 5
    end
  end
end
