FactoryGirl.define do
  factory :node_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # Fixme requires node factory
    node_id 1
  end
end
