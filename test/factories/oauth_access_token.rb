FactoryBot.define do
  factory :oauth_access_token, :class => "Doorkeeper::AccessToken" do
    association :application, :factory => :oauth_application
  end
end
