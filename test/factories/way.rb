FactoryGirl.define do
  factory :way do
    timestamp Time.now
    visible true
    version 1

    changeset
  end
end
