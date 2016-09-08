FactoryGirl.define do
  factory :diary_entry do
    sequence(:title) { |n| "Diary entry #{n}" }
    sequence(:body) { |n| "This is diary entry #{n}" }

    # Fixme requires User Factory
    user_id 1
  end
end
