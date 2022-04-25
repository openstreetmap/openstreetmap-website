FactoryBot.define do
  factory :access_token do
    user
    client_application
  end
end
