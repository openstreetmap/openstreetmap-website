# Be sure to restart your web server when you modify this file.

# Limit each rails process to a 512Mb resident set size
Process.setrlimit Process::RLIMIT_AS, 640*1024*1024, Process::RLIM_INFINITY

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Application constants needed for routes.rb - must go before Initializer call
API_VERSION = ENV['OSM_API_VERSION'] || '0.5'

# Custom logger class to format messages sensibly
class OSMLogger < Logger
  def format_message(severity, time, progname, msg)
    "[%s.%06d #%d] %s\n" % [time.strftime("%Y-%m-%d %H:%M:%S"), time.usec, $$, msg.sub(/^\n+/, "")]
  end
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use our custom logger
  config.logger = OSMLogger.new(config.log_path)
  config.logger.level = Logger.const_get(config.log_level.to_s.upcase)

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :sql_session_store

  # Unfortunately SqlSessionStore is a plugin which has not been
  # loaded yet, so we have to do things the hard way...
  config.after_initialize do
    ActionController::Base.session_store = :sql_session_store
    SqlSessionStore.session_class = MysqlSession
  end

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Hack the AssetTagHelper to make asset tagging work better
module ActionView
  module Helpers
    module AssetTagHelper
      private
        alias :old_compute_public_path :compute_public_path

        def compute_public_path(source, dir, ext)
          path = old_compute_public_path(source, dir, ext)
          if path =~ /(.+)\?(\d+)\??$/
            path = "#{$1}/#{$2}"
          end
          path
        end
    end
  end
end

# Set to :readonly to put the API in read-only mode or :offline to
# take it completely offline
API_STATUS = :online

# Include your application configuration below
SERVER_URL = ENV['OSM_SERVER_URL'] || 'www.openstreetmap.org'

ActionMailer::Base.smtp_settings = {
  :address  => "localhost",
  :port  => 25, 
  :domain  => 'localhost',
} 

#Taming FCGI
#
COUNT = 0
MAX_COUNT = 10000




