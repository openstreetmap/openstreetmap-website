FactoryBot.define do
  factory :community do
    # Make sure the ranges make sense.
    lat1, lat2 = Array.new(2) { Random.rand(-90.0..90.0) }.sort
    lon1, lon2 = Array.new(2) { Random.rand(-90.0..90.0) }.sort
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
