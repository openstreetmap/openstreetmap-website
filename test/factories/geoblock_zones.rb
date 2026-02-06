# frozen_string_literal: true

FactoryBot.define do
  factory :moderation_zone do
    sequence(:name) { |n| "Moderation Zone #{n}" }
    sequence(:reason) { |n| "Reason #{n}" }
    creator { association :user }

    trait :seville_cathedral do
      zone do
        <<~GEOMETRY
          POLYGON((
            -5.994110 37.386714,
            -5.993954 37.385371,
            -5.993621 37.385124,
            -5.992162 37.385239,
            -5.992264 37.386309,
            -5.992506 37.386467,
            -5.992559 37.386842,
            -5.994110 37.386714
          ))
        GEOMETRY
      end
    end
  end
end
