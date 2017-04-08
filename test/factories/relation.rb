FactoryGirl.define do
  factory :relation do
    timestamp Time.now
    visible true
    version 1

    changeset
  end
end
