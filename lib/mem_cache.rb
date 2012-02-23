class MemCache < Memcached::Rails
  DEFAULT_OPTIONS = Memcached::DEFAULTS.merge(Memcached::Rails::DEFAULTS)

  MemCacheError = Memcached::Error

  @@connections = []

  def initialize(options = {})
    options.reverse_merge! :namespace_separator => ":"

    super(MEMCACHE_SERVERS, options)

    @@connections.push(self)

    ObjectSpace.define_finalizer(self, lambda { |connection|
      @@connections.remove(connection)
    })
  end

  def self.connections
    @@connections
  end
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      MemCache.connections.each { |connection| connection.reset }
    end
  end
end
