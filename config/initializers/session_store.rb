# Be sure to restart your server when you modify this file.

if defined?(MEMCACHE_SERVERS)
  Rails.application.config.session_store :mem_cache_store, :memcache_server => MEMCACHE_SERVERS, :namespace => "rails:session", :key => "_osm_session"
else
  Rails.application.config.session_store :cache_store, :key => "_osm_session", :cache => ActiveSupport::Cache::MemoryStore.new
end
