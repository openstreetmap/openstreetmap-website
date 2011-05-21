# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  unless  STATUS == :database_offline
    config.gem 'composite_primary_keys', :version => '2.2.2'
  end
  config.gem 'libxml-ruby', :version => '>= 1.1.1', :lib => 'libxml'
  config.gem 'rmagick', :lib => 'RMagick'
  config.gem 'oauth', :version => '>= 0.4.3'
  config.gem 'oauth-plugin', :version => '0.3.14'
  config.gem 'httpclient'
  config.gem 'SystemTimer', :version => '>= 1.1.3', :lib => 'system_timer'
  config.gem 'sanitize'
  config.gem 'i18n', :version => '= 0.4.1'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
 
  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  if STATUS == :database_offline
    config.frameworks -= [ :active_record ]
    config.eager_load_paths = []
  end

  # Activate observers that should always be running
  config.active_record.observers = :spam_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql
end
