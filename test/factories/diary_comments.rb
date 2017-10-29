FactoryBot.define do
  factory :diary_comment do
    sequence(:body) { |n| "This is diary comment #{n}" }

    diary_entry
    user
  end
end
