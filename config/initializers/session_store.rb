# Be sure to restart your server when you modify this file.

if defined?(MEMCACHE_SERVERS)
  OpenStreetMap::Application.config.session_store :mem_cache_store, :memcache_servers => MEMCACHE_SERVERS, :namespace => "rails:session", :key => "_osm_session"
else
  OpenStreetMap::Application.config.session_store :cache_store, :key => '_osm_session'
end
