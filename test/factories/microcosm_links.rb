FactoryBot.define do
  factory :microcosm_link do
    microcosm
    site { "website" }
    url { "http://example.com" }
  end
end
