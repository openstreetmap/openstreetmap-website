# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger
OmniAuth.config.failure_raise_out_environments = []
OmniAuth.config.allowed_request_methods = [:post, :patch]

google_options = { :name => "google", :scope => "email", :access_type => "online" }
apple_options = { :name => "apple", :scope => "email name" }
facebook_options = { :name => "facebook", :scope => "email", :client_options => { :site => "https://graph.facebook.com/v17.0", :authorize_url => "https://www.facebook.com/v17.0/dialog/oauth" } }
microsoft_options = { :name => "microsoft", :scope => "openid User.Read" }
github_options = { :name => "github", :scope => "user:email" }
wikipedia_options = { :name => "wikipedia", :client_options => { :site => "https://meta.wikimedia.org" } }

google_options[:openid_realm] = Settings.google_openid_realm if Settings.key?(:google_openid_realm)

apple_options[:team_id] = Settings.apple_team_id if Settings.key?(:apple_team_id)
apple_options[:key_id] = Settings.apple_key_id if Settings.key?(:apple_key_id)
apple_options[:pem] = Settings.apple_private_key if Settings.key?(:apple_private_key)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Settings.google_auth_id, Settings.google_auth_secret, google_options if Settings.key?(:google_auth_id)
  provider :apple, Settings.apple_auth_id, "", apple_options if Settings.key?(:apple_auth_id)
  provider :facebook, Settings.facebook_auth_id, Settings.facebook_auth_secret, facebook_options if Settings.key?(:facebook_auth_id)
  provider :microsoft_graph, Settings.microsoft_auth_id, Settings.microsoft_auth_secret, microsoft_options if Settings.key?(:microsoft_auth_id)
  provider :github, Settings.github_auth_id, Settings.github_auth_secret, github_options if Settings.key?(:github_auth_id)
  provider :mediawiki, Settings.wikipedia_auth_id, Settings.wikipedia_auth_secret, wikipedia_options if Settings.key?(:wikipedia_auth_id)
end
