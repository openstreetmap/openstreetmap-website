# frozen_string_literal: true

FactoryBot.define do
  factory :gpx_event do
    sequence(:gpx_id)
    action { "added" }
  end
end
