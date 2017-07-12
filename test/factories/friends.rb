FactoryGirl.define do
  factory :friend do
    association :befriender, :factory => :user
    association :befriendee, :factory => :user
  end
end
