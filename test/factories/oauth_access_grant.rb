FactoryBot.define do
  factory :oauth_access_grant, :class => "Doorkeeper::AccessGrant" do
    association :resource_owner_id, :factory => :user
    association :application, :factory => :oauth_application

    expires_in { 86400 }
    redirect_uri { application.redirect_uri }
  end
end
