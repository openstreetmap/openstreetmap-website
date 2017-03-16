FactoryGirl.define do
  factory :redaction do
    sequence(:title) { |n| "Redaction #{n}" }
    sequence(:description) { |n| "Description of redaction #{n}" }

    user
  end
end
