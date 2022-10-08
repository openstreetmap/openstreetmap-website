FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "Title #{n}" }
    moment { Time.now.utc + 1000 }
    sequence(:location) { |n| "Location #{n}" }
    sequence(:location_url) { |n| "https://example.com/app/#{n}" }
    sequence(:description) { |n| "Description #{n}" }
    community
    latitude { rand(-90.0...90.0) }
    longitude { rand(-180.0...180.0) }

    # TODO: trait for event with attendees
  end
end
