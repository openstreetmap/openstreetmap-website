FactoryGirl.define do
  factory :issue do
    # Default to reporting users
    association :reportable, :factory => :user

    # reported_user_id
    association :user, :factory => :user
  end
end
