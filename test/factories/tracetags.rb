# frozen_string_literal: true

FactoryBot.define do
  factory :tracetag do
    sequence(:tag) { |n| "Tag #{n}" }

    trace
  end
end
