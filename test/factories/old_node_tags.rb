FactoryGirl.define do
  factory :old_node_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # Fixme requires old_node factory
    node_id 1
    version 1
  end
end
