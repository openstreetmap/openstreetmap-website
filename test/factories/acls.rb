# frozen_string_literal: true

FactoryBot.define do
  factory :acl do
    sequence(:k) { |n| "Key #{n}" }
  end
end
