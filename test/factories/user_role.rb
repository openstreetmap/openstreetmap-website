FactoryBot.define do
  factory :user_role do
    user
    granter :factory => :user
  end
end
