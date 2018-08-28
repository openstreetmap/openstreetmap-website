FactoryBot.define do
  factory :report do
    sequence(:details) { |n| "Report details #{n}" }
    category { "other" }
    issue
    user
  end
end
