# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Set the server URL
SERVER_URL = ENV['OSM_SERVER_URL'] || 'www.openstreetmap.org'

# Set the generator
GENERATOR = ENV['OSM_SERVER_GENERATOR'] || 'OpenStreetMap server'

# Settings for generated emails (e.g. signup confirmation
EMAIL_FROM = ENV['OSM_EMAIL_FROM'] || 'OpenStreetMap <webmaster@openstreetmap.org>'
EMAIL_RETURN_PATH = ENV['OSM_EMAIL_RETURN_PATH'] || 'bounces@openstreetmap.org'

# Application constants needed for routes.rb - must go before Initializer call
API_VERSION = ENV['OSM_API_VERSION'] || '0.6'

# Set application status - possible settings are:
#
#   :online - online and operating normally
#   :api_readonly - site online but API in read-only mode
#   :api_offline - site online but API offline
#   :database_readonly - database and site in read-only mode
#   :database_offline - database offline with site in emergency mode
#   :gpx_offline - gpx storage offline
#
OSM_STATUS = :online

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  if OSM_STATUS == :database_offline
    config.frameworks -= [ :active_record ]
    config.eager_load_paths = []
  end

  # Specify gems that this application depends on.
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  unless  OSM_STATUS == :database_offline
    config.gem 'composite_primary_keys', :version => '2.2.2'
  end
  config.gem 'libxml-ruby', :version => '>= 1.1.1', :lib => 'libxml'
  config.gem 'rmagick', :lib => 'RMagick'
  config.gem 'oauth', :version => '>= 0.3.6'
  config.gem 'httpclient'
  config.gem 'SystemTimer', :version => '>= 1.1.3', :lib => 'system_timer'
  config.gem 'sanitize'

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Configure cache
  config.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :key    => '_osm_session',
    :secret => 'd886369b1e709c61d1f9fcb07384a2b96373c83c01bfc98c6611a9fe2b6d0b14215bb360a0154265cccadde5489513f2f9b8d9e7b384a11924f772d2872c2a1f'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  unless  OSM_STATUS == :database_offline
    config.action_controller.session_store = :sql_session_store
  end

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = :spam_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
end
