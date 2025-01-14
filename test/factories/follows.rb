FactoryBot.define do
  factory :follow do
    follower :factory => :user
    following :factory => :user
  end
end
