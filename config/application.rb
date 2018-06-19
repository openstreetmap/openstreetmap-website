require_relative "boot"

require_relative "preinitializer"

if STATUS == :database_offline
  require "action_controller/railtie"
  require "action_mailer/railtie"
  require "active_model/railtie"
  require "sprockets/railtie"
  require "rails/test_unit/railtie"
else
  require "rails/all"
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenStreetMap
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{config.root}/lib]

    # This defaults to true from rails 5.0 but our code doesn't comply
    # with it at all so we turn it off
    config.active_record.belongs_to_required_by_default = false

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql unless STATUS == :database_offline

    # Don't eager load models when the database is offline
    config.paths["app/models"].skip_eager_load! if STATUS == :database_offline

    # Use memcached for caching if required
    config.cache_store = :mem_cache_store, MEMCACHE_SERVERS, { :namespace => "rails:cache" } if defined?(MEMCACHE_SERVERS)

    # Use logstash for logging if required
    if defined?(LOGSTASH_PATH)
      config.logstasher.enabled = true
      config.logstasher.suppress_app_log = false
      config.logstasher.logger_path = LOGSTASH_PATH
      config.logstasher.log_controller_parameters = true
    end
  end
end
