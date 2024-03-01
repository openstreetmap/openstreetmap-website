# frozen_string_literal: true

Doorkeeper::OpenidConnect.configure do
  issuer do |_resource_owner, _application|
    "#{Settings.server_protocol}://#{Settings.server_url}"
  end

  signing_key Settings.doorkeeper_signing_key

  subject_types_supported [:public]

  resource_owner_from_access_token do |access_token|
    User.find_by(:id => access_token.resource_owner_id)
  end

  auth_time_from_resource_owner do |resource_owner|
    # empty block necessary as a workaround to missing configuration
    # when no auth_time claim is provided
  end

  subject do |resource_owner, _application|
    resource_owner.id
  end

  protocol do
    Settings.server_protocol.to_sym
  end

  claims do
    claim :preferred_username, :scope => :openid do |resource_owner, _scopes, _access_token|
      resource_owner.display_name
    end

    claim :email, :scope => :read_email, :response => [:id_token, :user_info] do |resource_owner, _scopes, _access_token|
      resource_owner.email
    end
  end
end
