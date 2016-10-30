FactoryGirl.define do
  factory :old_way_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # Fixme requires old_way factory
    way_id 1
    version 1
  end
end
