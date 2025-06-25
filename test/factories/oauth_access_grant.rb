FactoryBot.define do
  factory :oauth_access_grant, :class => "Doorkeeper::AccessGrant" do
    application :factory => :oauth_application

    resource_owner_id { user.id }

    expires_in { 86400 }
    redirect_uri { application.redirect_uri }

    transient do
      user { create(:user) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    end
  end
end
