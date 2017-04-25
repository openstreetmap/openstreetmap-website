FactoryGirl.define do
  factory :relation do
    timestamp Time.now
    visible true
    version 1

    changeset

    trait :deleted do
      visible false
    end
  end
end
