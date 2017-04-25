FactoryGirl.define do
  factory :old_way do
    timestamp Time.now
    visible true
    version 1

    changeset
    association :current_way, :factory => :way
  end
end
