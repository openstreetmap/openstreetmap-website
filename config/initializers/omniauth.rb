require "openid/fetchers"
require "openid/util"

CA_BUNDLES = ["/etc/ssl/certs/ca-certificates.crt", "/etc/pki/tls/cert.pem"].freeze

OpenID.fetcher.ca_file = CA_BUNDLES.find { |f| File.exist?(f) }
OpenID::Util.logger = Rails.logger

OmniAuth.config.logger = Rails.logger
OmniAuth.config.failure_raise_out_environments = []

if Settings.key?(:memcache_servers)
  require "openid/store/memcache"

  openid_store = OpenID::Store::Memcache.new(Dalli::Client.new(Settings.memcache_servers, :namespace => "rails"))
else
  require "openid/store/filesystem"

  openid_store = OpenID::Store::Filesystem.new(Rails.root.join("tmp", "openids"))
end

openid_options = { :name => "openid", :store => openid_store }
google_options = { :name => "google", :scope => "email", :access_type => "online" }
facebook_options = { :name => "facebook", :scope => "email", :client_options => { :site => "https://graph.facebook.com/v4.0", :authorize_url => "https://www.facebook.com/v4.0/dialog/oauth" } }
windowslive_options = { :name => "windowslive", :scope => "wl.signin,wl.emails" }
github_options = { :name => "github", :scope => "user:email" }
wikipedia_options = { :name => "wikipedia", :client_options => { :site => "https://meta.wikimedia.org" } }

google_options[:openid_realm] = Settings.google_openid_realm if Settings.key?(:google_openid_realm)

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid, openid_options
  provider :google_oauth2, Settings.google_auth_id, Settings.google_auth_secret, google_options if Settings.key?(:google_auth_id)
  provider :facebook, Settings.facebook_auth_id, Settings.facebook_auth_secret, facebook_options if Settings.key?(:facebook_auth_id)
  provider :windowslive, Settings.windowslive_auth_id, Settings.windowslive_auth_secret, windowslive_options if Settings.key?(:windowslive_auth_id)
  provider :github, Settings.github_auth_id, Settings.github_auth_secret, github_options if Settings.key?(:github_auth_id)
  provider :mediawiki, Settings.wikipedia_auth_id, Settings.wikipedia_auth_secret, wikipedia_options if Settings.key?(:wikipedia_auth_id)
end
