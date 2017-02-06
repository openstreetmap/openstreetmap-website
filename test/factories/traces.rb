FactoryGirl.define do
  factory :trace do
    sequence(:name) { |n| "Trace #{n}.gpx" }
    sequence(:description) { |n| "This is trace #{n}" }

    # Fixme requires User Factory
    user_id 1

    timestamp Time.now
    inserted true

    trait :deleted do
      visible false
    end

    transient do
      fixture nil
    end

    after(:create) do |trace, evaluator|
      if evaluator.fixture
        File.symlink(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.gpx"),
                     Rails.root.join("test", "gpx", "traces", "#{trace.id}.gpx"))
        File.symlink(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}.gif"),
                     Rails.root.join("test", "gpx", "images", "#{trace.id}.gif"))
        File.symlink(Rails.root.join("test", "gpx", "fixtures", "#{evaluator.fixture}_icon.gif"),
                     Rails.root.join("test", "gpx", "images", "#{trace.id}_icon.gif"))
      end
    end
  end
end
