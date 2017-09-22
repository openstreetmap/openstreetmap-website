FactoryGirl.define do
  factory :changeset do
    created_at Time.now.utc
    closed_at Time.now.utc + 1.day

    user

    trait :closed do
      created_at Time.now.utc - 5.hours
      closed_at Time.now.utc - 4.hours
    end

    factory :changeset_with_comments do
      transient do
        comment_count 1
      end

      after(:create) do |changeset, evaluator|
        create_list(:changeset_comment, evaluator.comment_count, :changeset => changeset)
      end
    end
  end
end
