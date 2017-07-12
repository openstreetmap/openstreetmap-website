FactoryGirl.define do
  factory :old_relation_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    old_relation
  end
end
