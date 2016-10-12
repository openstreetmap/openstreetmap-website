FactoryGirl.define do
  factory :friend do
    # Fixme requires User Factory
    user_id 1
    friend_user_id 2
  end
end
