FactoryBot.define do
  factory :issue_comment do
    sequence(:body) { |n| "This is issue comment #{n}" }

    issue
    user
  end
end
