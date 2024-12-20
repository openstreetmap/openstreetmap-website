FactoryBot.define do
  factory :message do
    sequence(:title) { |n| "Message #{n}" }
    sequence(:body) { |n| "Body text for message #{n}" }
    sent_on { Time.now.utc }

    sender :factory => :user
    recipient :factory => :user

    trait :unread do
      message_read { false }
    end

    trait :read do
      message_read { true }
    end

    trait :muted do
      muted { true }
    end
  end
end
