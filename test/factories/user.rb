FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:display_name) { |n| "User #{n}" }
    pass_crypt { Digest::MD5.hexdigest("test") }

    # These attributes are not the defaults, but in most tests we want
    # a 'normal' user who can log in without being redirected etc.
    after(:build) do |user, _evaluator|
      user.activate
    end

    terms_seen { true }
    terms_agreed { Time.now.utc }
    data_public { true }

    trait :with_home_location do
      home_lat { rand(-90.0...90.0) }
      home_lon { rand(-180.0...180.0) }
    end

    trait :pending do
      after(:build) do |user, _evaluator|
        user.deactivate
      end
    end

    trait :active do
      # status { "active" }
    end

    trait :confirmed do
      after(:build) do |user, _evaluator|
        user.confirm
      end
    end

    trait :suspended do
      after(:build) do |user, _evaluator|
        user.suspend
      end
    end

    trait :deleted do
      after(:build) do |user, _evaluator|
        user.soft_destroy
      end
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

    factory :super_user do
      after(:create) do |user, _evaluator|
        UserRole::ALL_ROLES.each do |role|
          create(:user_role, :role => role, :user => user)
        end
      end
    end
  end
end
