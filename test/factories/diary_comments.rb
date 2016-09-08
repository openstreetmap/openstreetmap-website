FactoryGirl.define do
  factory :diary_comment do
    sequence(:body) { |n| "This is diary comment #{n}" }

    diary_entry

    # Fixme requires User Factory
    user_id 1
  end
end
