FactoryGirl.define do
  factory :message do
    sequence(:title) { |n| "Message #{n}" }
    sequence(:body) { |n| "Body text for message #{n}" }
    sent_on Time.now

    association :sender, :factory => :user
    association :recipient, :factory => :user

    trait :unread do
      message_read false
    end

    trait :read do
      message_read true
    end
  end
end
