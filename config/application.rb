require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenStreetMap
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{config.root}/lib]

    # Force requests from old versions of IE (<= IE8) to be UTF-8 encoded.
    # This has defaulted to false since rails 6.0
    config.action_view.default_enforce_utf8 = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql unless Settings.status == "database_offline"

    # Use memcached for caching if required
    config.cache_store = :mem_cache_store, Settings.memcache_servers, { :namespace => "rails:cache" } if Settings.key?(:memcache_servers)

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation cannot be found).
    config.i18n.fallbacks = true

    # Use logstash for logging if required
    if Settings.key?(:logstash_path)
      config.logstasher.enabled = true
      config.logstasher.suppress_app_log = false
      config.logstasher.logger_path = Settings.logstash_path
      config.logstasher.log_controller_parameters = true
    end

    config.active_record.database_selector = { :delay => 2.seconds }
    config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
    config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
  end
end
