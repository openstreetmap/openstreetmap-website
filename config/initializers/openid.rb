if defined?(MEMCACHE_SERVERS)
  require "openid/store/memcache"

  OpenIdAuthentication.store = OpenID::Store::Memcache.new(MemCache.new(:namespace => "rails", :string_return_types => true))
else
  OpenIdAuthentication.store = :file
end
