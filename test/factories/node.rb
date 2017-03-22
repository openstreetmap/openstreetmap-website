FactoryGirl.define do
  factory :node do
    latitude 1 * GeoRecord::SCALE
    longitude 1 * GeoRecord::SCALE

    # FIXME: needs changeset factory
    changeset_id 1

    visible true
    timestamp Time.now
    version 1
  end
end
