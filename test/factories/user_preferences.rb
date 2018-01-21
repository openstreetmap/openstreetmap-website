FactoryBot.define do
  factory :user_preference do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    user
  end
end
