FactoryBot.define do
  factory :community_link do
    community
    site { "website" }
    url { "https://example.com" }
  end
end
