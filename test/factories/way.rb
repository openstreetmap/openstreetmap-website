FactoryGirl.define do
  factory :way do
    timestamp Time.now
    visible true
    version 1

    changeset

    trait :deleted do
      visible false
    end
  end
end
