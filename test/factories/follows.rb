FactoryBot.define do
  factory :follow do
    befriender :factory => :user
    befriendee :factory => :user
  end
end
