require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OpenStreetMap
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(:ignore => %w[assets classic_pagination tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql unless Settings.status == "database_offline"

    # Use memcached for caching if required
    config.cache_store = :mem_cache_store, Settings.memcache_servers, { :namespace => "rails:cache" } if Settings.key?(:memcache_servers)

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation cannot be found).
    config.i18n.fallbacks = true
    # Enables custom error message formats
    config.active_model.i18n_customize_full_message = true

    # Use logstash for logging if required
    if Settings.key?(:logstash_path)
      config.logstasher.enabled = true
      config.logstasher.suppress_app_log = false
      config.logstasher.logger_path = Settings.logstash_path
      config.logstasher.log_controller_parameters = true
    end
  end
end
