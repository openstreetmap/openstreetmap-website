FactoryBot.define do
  factory :issue do
    # Default to reporting users
    association :reportable, :factory => :user
    association :reported_user, :factory => :user
  end
end
