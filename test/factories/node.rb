FactoryGirl.define do
  factory :node do
    latitude 1 * GeoRecord::SCALE
    longitude 1 * GeoRecord::SCALE

    changeset

    visible true
    timestamp Time.now
    version 1
  end
end
