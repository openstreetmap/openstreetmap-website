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
  end
end
