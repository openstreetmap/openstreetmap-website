FactoryBot.define do
  factory :community_link do
    community
    text { "website" }
    url { "https://example.com" }
  end
end
