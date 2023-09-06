FactoryBot.define do
  factory :friendship do
    befriender :factory => :user
    befriendee :factory => :user
  end
end
