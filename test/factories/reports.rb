FactoryBot.define do
  factory :report do
    sequence(:details) { |n| "Report details #{n}" }
    issue
    user
  end
end
