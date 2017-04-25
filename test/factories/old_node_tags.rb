FactoryGirl.define do
  factory :old_node_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    old_node
  end
end
