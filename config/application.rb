require File.expand_path("../boot", __FILE__)

require File.expand_path("../preinitializer", __FILE__)

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
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true unless STATUS == :database_offline

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql unless STATUS == :database_offline

    # Don't eager load models when the database is offline
    config.paths["app/models"].skip_eager_load! if STATUS == :database_offline

    # Use memcached for caching if required
    if defined?(MEMCACHE_SERVERS)
      config.cache_store = :mem_cache_store, MEMCACHE_SERVERS, { :namespace => "rails:cache" }
    end

    # Use logstash for logging if required
    if defined?(LOGSTASH_PATH)
      config.logstasher.enabled = true
      config.logstasher.suppress_app_log = false
      config.logstasher.logger_path = LOGSTASH_PATH
      config.logstasher.log_controller_parameters = true
    end

    # Configure image optimisation
    config.assets.image_optim = YAML.load_file("#{Rails.root}/config/image_optim.yml")
  end
end
