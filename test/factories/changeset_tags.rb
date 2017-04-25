FactoryGirl.define do
  factory :changeset_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    changeset
  end
end
