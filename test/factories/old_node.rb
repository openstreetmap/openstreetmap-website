FactoryBot.define do
  factory :old_node do
    latitude { 1 * GeoRecord::SCALE }
    longitude { 1 * GeoRecord::SCALE }

    changeset
    association :current_node, :factory => :node

    visible { true }
    timestamp { Time.now }
    version { 1 }
  end
end
