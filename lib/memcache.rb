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

  # def active?
  #   not servers.empty?
  # end

  # def servers
  #   server_structs.map { |ss| Server.new(ss) }
  # end

  # class Server
  #   def initialize(details)
  #     @details = details
  #   end

  #   def alive?
  #     @details.cached_errno == 0
  #   end
  # end
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      MemCache.connections.each do |connection|
        Rails.logger.info "Resetting connection #{connection.object_id}"
        connection.reset
      end
    end
  end
end
