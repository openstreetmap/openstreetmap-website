FactoryGirl.define do
  factory :relation_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # Fixme requires relation factory
    relation_id 1
  end
end
