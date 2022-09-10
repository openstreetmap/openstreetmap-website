FactoryBot.define do
  factory :microcosm do
    sequence(:name) { |n| "Microcosm #{n}" }
    sequence(:description) { |n| "This is description #{n}" }
    sequence(:location) { |n| "This is location #{n}" }
    organizer :factory => :user
    latitude { rand(-90.0...90.0) }
    longitude { rand(-180.0...180.0) }
    min_lat { rand(-90.0...90.0) }
    max_lat { rand(-90.0...90.0) }
    min_lon { rand(-180.0...180.0) }
    max_lon { rand(-180.0...180.0) }
  end
end
