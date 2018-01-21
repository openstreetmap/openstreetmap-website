FactoryBot.define do
  factory :old_way_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    old_way
  end
end
