FactoryGirl.define do
  factory :way_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # Fixme requires way factory
    way_id 1
  end
end
