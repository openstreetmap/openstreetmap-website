FactoryGirl.define do
  factory :message do
    sequence(:title) { |n| "Message #{n}" }
    sequence(:body) { |n| "Body text for message #{n}" }
    sent_on Time.now

    # FIXME: needs user factory
    from_user_id 1

    # FIXME: needs user factory
    to_user_id 2

    trait :unread do
      message_read false
    end

    trait :read do
      message_read true
    end
  end
end
