FactoryGirl.define do
  factory :relation_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    relation
  end
end
