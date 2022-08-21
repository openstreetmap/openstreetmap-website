FactoryBot.define do
  factory :microcosm do
    name { "MyString" }
    description { "MyText" }
    sequence(:location) { |n| "This is location #{n}" }
    lat { rand(-90.0...90.0) }
    lon { rand(-180.0...180.0) }
    min_lat { rand(-90.0...90.0) }
    max_lat { rand(-90.0...90.0) }
    min_lon { rand(-180.0...180.0) }
    max_lon { rand(-180.0...180.0) }
  end
end
