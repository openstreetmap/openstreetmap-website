# frozen_string_literal: true

FactoryBot.define do
  factory :social_link do
    sequence(:url) { |n| "https://test.com/#{n}" }
    user
  end
end
