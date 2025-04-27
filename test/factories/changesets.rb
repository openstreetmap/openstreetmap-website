# frozen_string_literal: true

FactoryBot.define do
  factory :changeset do
    transient do
      bbox { nil }
    end

    created_at { Time.now.utc }
    closed_at { Time.now.utc + 1.day }
    min_lon { (bbox[0] * GeoRecord::SCALE).round if bbox }
    min_lat { (bbox[1] * GeoRecord::SCALE).round if bbox }
    max_lon { (bbox[2] * GeoRecord::SCALE).round if bbox }
    max_lat { (bbox[3] * GeoRecord::SCALE).round if bbox }

    user

    trait :closed do
      created_at { Time.now.utc - 5.hours }
      closed_at { Time.now.utc - 4.hours }
    end
  end
end
