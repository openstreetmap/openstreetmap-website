# Be sure to restart your server when you modify this file.

if defined?(MEMCACHE_SERVERS)
  cache = MemCache.new(:namespace => "rails:session", :string_return_types => true)

  OpenStreetMap::Application.config.session_store :mem_cache_store, :cache => cache, :key => "_osm_session"
else
  OpenStreetMap::Application.config.session_store :cache_store, :key => '_osm_session'
end
