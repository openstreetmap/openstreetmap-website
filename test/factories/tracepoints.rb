FactoryBot.define do
  factory :tracepoint do
    trackid { 1 }
    latitude { 1 * GeoRecord::SCALE }
    longitude { 1 * GeoRecord::SCALE }
    # tile { QuadTile.tile_for_point(1,1) }
    timestamp { Time.now }

    trace
  end
end
