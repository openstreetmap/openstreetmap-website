FactoryBot.define do
  factory :issue do
    # Default to reporting users
    association :reportable, :factory => :user
    association :reported_user, :factory => :user

    # Default to assigning to an administrator
    assigned_role "administrator"
  end
end
