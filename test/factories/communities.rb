FactoryBot.define do
  factory :community do
    # Make sure the ranges make sense.
    lat1 = Random.rand(-90.0..90.0)
    lat2 = Random.rand(-90.0..90.0)
    lat1, lat2 = lat2, lat1 if lat2 < lat1
    lon1 = Random.rand(-180.0..180.0)
    lon2 = Random.rand(-180.0..180.0)
    lon1, lon2 = lon2, lon1 if lon2 < lon1
    lat = Random.rand(lat1..lat2)
    lon = Random.rand(lon1..lon2)

    sequence(:name) { |n| "Community #{n}" }
    sequence(:description) { |n| "This is description #{n}" }
    sequence(:location) { |n| "This is location #{n}" }
    organizer :factory => :user
    latitude { lat }
    longitude { lon }
    min_lat { lat1 }
    max_lat { lat2 }
    min_lon { lon1 }
    max_lon { lon2 }
  end
end
