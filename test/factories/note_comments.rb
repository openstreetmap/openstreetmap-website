# frozen_string_literal: true

FactoryBot.define do
  factory :note_comment do
    sequence(:body) { |n| "This is note comment #{n}" }
    visible { true }
    event { "commented" }
    note
  end
end
