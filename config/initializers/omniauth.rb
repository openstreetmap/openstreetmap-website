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
