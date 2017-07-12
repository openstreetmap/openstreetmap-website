FactoryGirl.define do
  factory :acl do
    sequence(:k) { |n| "Key #{n}" }
  end
end
