FactoryGirl.define do
  factory :user_preference do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    # FIXME: needs user factory
    user_id 1
  end
end
