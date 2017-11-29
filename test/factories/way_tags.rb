FactoryBot.define do
  factory :way_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    way
  end
end
