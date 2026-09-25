# frozen_string_literal: true

FactoryBot.define do
  factory :diary_entry do
    sequence(:title) { |n| "Diary entry #{n}" }
    sequence(:body) { |n| "This is diary entry #{n}" }

    language { Language.find_by(:code => "en") || create(:language, :code => "en") }
    user
  end
end
