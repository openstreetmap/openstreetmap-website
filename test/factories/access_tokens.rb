# frozen_string_literal: true

FactoryBot.define do
  factory :access_token do
    user
    client_application
  end
end
