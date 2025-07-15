FactoryBot.define do
  factory :oauth_access_token, :class => "Doorkeeper::AccessToken" do
    application :factory => :oauth_application

    resource_owner_id { user.id }

    transient do
      user { create(:user) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
    end
  end
end
