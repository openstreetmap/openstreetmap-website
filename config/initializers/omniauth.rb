require "openid/fetchers"

CA_BUNDLES = ["/etc/ssl/certs/ca-certificates.crt", "/etc/pki/tls/cert.pem"]

OpenID.fetcher.ca_file = CA_BUNDLES.find { |f| File.exist?(f) }

OmniAuth.config.logger = Rails.logger
OmniAuth.config.failure_raise_out_environments = []

if defined?(MEMCACHE_SERVERS)
  require "openid/store/memcache"

  openid_store = OpenID::Store::Memcache.new(Dalli::Client.new(MEMCACHE_SERVERS, :namespace => "rails"))
else
  require "openid/store/filesystem"

  openid_store = OpenID::Store::Filesystem.new(Rails.root.join("tmp/openids"))
end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid, :name => "openid", :store => openid_store
end

# Pending fix for: https://github.com/intridea/omniauth/pull/795
module OmniAuth
  module Strategy
    def mock_callback_call_with_origin
      @env["omniauth.origin"] = session["omniauth.origin"]

      mock_callback_call_without_origin
    end

    alias_method_chain :mock_callback_call, :origin
  end
end
