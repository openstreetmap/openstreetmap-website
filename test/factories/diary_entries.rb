# frozen_string_literal: true

FactoryBot.define do
  factory :diary_entry do
    sequence(:title) { |n| "Diary entry #{n}" }
    sequence(:body) { |n| "This is diary entry #{n}" }

    user
  end
end
