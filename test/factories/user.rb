FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:display_name) { |n| "User #{n}" }
    pass_crypt Digest::MD5.hexdigest("test")

    trait :with_home_location do
      home_lat { rand(-90.0...90.0) }
      home_lon { rand(-180.0...180.0) }
    end

    factory :moderator_user do
      after(:create) do |user, _evaluator|
        create(:user_role, :role => "moderator", :user => user)
      end
    end

    factory :administrator_user do
      after(:create) do |user, _evaluator|
        create(:user_role, :role => "administrator", :user => user)
      end
    end
  end
end
