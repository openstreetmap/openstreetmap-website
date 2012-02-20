if defined?(PhusionPassenger) and defined?(MEMCACHE_SERVERS)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      MEMCACHE = MEMCACHE.clone
      RAILS_CACHE = ActiveSupport::Cache::MemCacheStore.new(MEMCACHE, :compress => true)
      ActionController::Base.cache_store = RAILS_CACHE
    end
  end
end
