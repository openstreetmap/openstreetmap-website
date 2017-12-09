FactoryGirl.define do
  factory :oauth_token do
    user
    client_application
  end
end
