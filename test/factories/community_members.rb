FactoryBot.define do
  factory :community_member do
    community
    user
    role { CommunityMember::Roles::MEMBER }

    trait :organizer do
      role { CommunityMember::Roles::ORGANIZER }
    end
  end
end
