FactoryGirl.define do
  factory :user_role do
    user
    association :granter, :factory => :user
  end
end
