FactoryBot.define do
  factory :microcosm_member do
    microcosm
    user
    role { MicrocosmMember::Roles::MEMBER }

    trait :organizer do
      role { MicrocosmMember::Roles::ORGANIZER }
    end
  end
end
