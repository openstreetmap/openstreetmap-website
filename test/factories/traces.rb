# frozen_string_literal: true

FactoryBot.define do
  factory :trace do
    sequence(:name) { |n| "Trace #{n}.gpx" }
    sequence(:description) { |n| "This is trace #{n}" }

    user

    timestamp { Time.now.utc }
    inserted { true }
    size { 10 }

    trait :deleted do
      visible { false }
    end

    transient do
      fixture { nil }
      fixture_ext { nil }
    end

    after(:build) do |user, evaluator|
      if evaluator.fixture
        ext = evaluator.fixture_ext || "gpx"
        user.file.attach(Rack::Test::UploadedFile.new(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.#{ext}")))

        if evaluator.inserted
          user.image.attach(Rack::Test::UploadedFile.new(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.gif")))
          user.icon.attach(Rack::Test::UploadedFile.new(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}_icon.gif")))
        end
      end
    end
  end
end
