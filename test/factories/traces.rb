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

    # Insert a trace with a legacy visibility (public/private) by skipping
    # validations, so tests can check that old traces still work.
    trait :without_validations do
      to_create { |instance| instance.save(:validate => false) }
    end

    transient do
      fixture { nil }
    end

    after(:build) do |user, evaluator|
      if evaluator.fixture
        user.file.attach(Rack::Test::UploadedFile.new(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.gpx")))

        if evaluator.inserted
          user.image.attach(Rack::Test::UploadedFile.new(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.gif")))
          user.icon.attach(Rack::Test::UploadedFile.new(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}_icon.gif")))
        end
      end
    end
  end
end
