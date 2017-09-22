FactoryGirl.define do
  factory :changeset_comment do
    sequence(:body) { |n| "Changeset comment #{n}" }
    visible true

    changeset

    association :author, :factory => :user

    trait :visible do
      visible true
    end

    trait :hidden do
      visible false
    end
  end
end
