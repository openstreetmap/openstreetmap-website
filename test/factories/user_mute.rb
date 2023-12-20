FactoryBot.define do
  factory :user_mute do
    owner :factory => :user
    subject :factory => :user
  end
end
