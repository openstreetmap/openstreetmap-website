FactoryBot.define do
  factory :friendship do
    association :befriender, :factory => :user
    association :befriendee, :factory => :user
  end
end
