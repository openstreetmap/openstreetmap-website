FactoryGirl.define do
  factory :old_relation_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # Fixme requires old_relation factory
    relation_id 1
    version 1
  end
end
