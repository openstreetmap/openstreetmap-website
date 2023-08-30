FactoryBot.define do
  factory :issue do
    # Default to reporting users
    association :reportable, :factory => :user
    association :reported_user, :factory => :user

    # Default to assigning to an administrator
    assigned_role { "administrator" }

    # Optionally create some reports for this issue
    factory :issue_with_reports do
      transient do
        reports_count { 1 }
      end

      after(:create) do |issue, evaluator|
        create_list(:report, evaluator.reports_count, :issue => issue)
      end
    end
  end
end
