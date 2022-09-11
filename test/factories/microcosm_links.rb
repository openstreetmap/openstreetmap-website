FactoryBot.define do
  factory :microcosm_link do
    microcosm
    site { "website" }
    url { "https://example.com" }
  end
end
