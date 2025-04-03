FactoryBot.define do
  factory :note_version do
    latitude { 1 * GeoRecord::SCALE }
    longitude { 1 * GeoRecord::SCALE }
    description { "Default note's description" }
    tile { 1 }
    status { "open" }
    note_comment_id { 1 }

    note :factory => :note

    timestamp { Time.now.utc }
    version { 1 }
  end
end
