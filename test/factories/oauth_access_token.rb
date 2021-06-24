FactoryBot.define do
  factory :oauth_access_token, :class => "Doorkeeper::AccessToken" do
    association :resource_owner_id, :factory => :user
    association :application, :factory => :oauth_application
  end
end
