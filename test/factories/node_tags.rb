FactoryBot.define do
  factory :node_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    node
  end
end
