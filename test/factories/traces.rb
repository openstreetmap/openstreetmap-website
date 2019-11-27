FactoryBot.define do
  factory :trace do
    sequence(:name) { |n| "Trace #{n}.gpx" }
    sequence(:description) { |n| "This is trace #{n}" }

    user

    timestamp { Time.now }
    inserted { true }
    size { 10 }

    trait :deleted do
      visible { false }
    end

    transient do
      fixture { nil }
    end

    after(:create) do |trace, evaluator|
      if evaluator.fixture
        File.symlink(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.gpx"),
                     File.join(Settings.gpx_trace_dir, "#{trace.id}.gpx"))
        File.symlink(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.gif"),
                     File.join(Settings.gpx_image_dir, "#{trace.id}.gif"))
        File.symlink(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}_icon.gif"),
                     File.join(Settings.gpx_image_dir, "#{trace.id}_icon.gif"))
      end
    end
  end
end
