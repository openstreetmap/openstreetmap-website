FactoryBot.define do
  factory :event do
    title { "MyString" }
    moment { "2019-09-05T92:08:02" }
    location { "Neverland" }
    location_url { "https://example.org" }
    description { "MyText" }
    microcosm
    latitude { 12.34 }
    longitude { 56.78 }
  end
end
