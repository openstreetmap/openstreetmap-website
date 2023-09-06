FactoryBot.define do
  factory :old_node do
    latitude { 1 * GeoRecord::SCALE }
    longitude { 1 * GeoRecord::SCALE }

    changeset
    current_node :factory => :node

    visible { true }
    timestamp { Time.now.utc }
    version { 1 }
  end
end
