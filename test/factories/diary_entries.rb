FactoryGirl.define do
  factory :diary_entry do
    sequence(:title) { |n| "Diary entry #{n}" }
    sequence(:body) { |n| "This is diary entry #{n}" }

    user
  end
end
