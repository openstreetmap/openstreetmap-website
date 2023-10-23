FactoryBot.define do
  factory :oauth_access_grant, :class => "Doorkeeper::AccessGrant" do
    resource_owner_id :factory => :user
    application :factory => :oauth_application

    expires_in { 86400 }
    redirect_uri { application.redirect_uri }
  end
end
