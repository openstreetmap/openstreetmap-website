FactoryGirl.define do
  factory :changeset_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # Fixme requires changeset factory
    changeset_id 1
  end
end
