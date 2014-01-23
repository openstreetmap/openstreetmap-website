if defined?(MEMCACHE_SERVERS)
  require "openid/store/memcache"

  OpenIdAuthentication.store = OpenID::Store::Memcache.new(Dalli::Client.new(MEMCACHE_SERVERS, :namespace => "rails"))
else
  OpenIdAuthentication.store = :file
end
