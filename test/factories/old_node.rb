FactoryGirl.define do
  factory :old_node do
    latitude 1 * GeoRecord::SCALE
    longitude 1 * GeoRecord::SCALE

    changeset

    # FIXME: needs node factory
    node_id 1000

    visible true
    timestamp Time.now
    version 1
  end
end
