OpenStreetMap::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both thread web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like nginx, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable Rails's static asset server (Apache or nginx will already do this).
  config.serve_static_assets = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = '1.0'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Set to :debug to see everything in the log.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different log path in production.
  if defined?(LOG_PATH)
    config.paths["log"] = LOG_PATH
  end

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  if defined?(MEMCACHE_SERVERS)
    config.cache_store = :mem_cache_store, MEMCACHE_SERVERS, { :namespace => "rails:cache" }
  end

  # Configure caching of static assets
  config.action_controller.page_cache_directory = Rails.public_path

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  config.assets.precompile += %w( index.js edit.js browse.js changeset.js welcome.js )
  config.assets.precompile += %w( user.js diary_entry.js swfobject.js )
  config.assets.precompile += %w( large-ltr.css small-ltr.css print-ltr.css )
  config.assets.precompile += %w( large-rtl.css small-rtl.css print-rtl.css )
  config.assets.precompile += %w( browse.css leaflet-all.css leaflet.ie.css )
  config.assets.precompile += %w( embed.js embed.css )
  config.assets.precompile += %w( images/marker-*.png img/*-handle.png )
  config.assets.precompile += %w( potlatch2.swf )
  config.assets.precompile += %w( potlatch2/assets.zip )
  config.assets.precompile += %w( potlatch2/FontLibrary.swf )
  config.assets.precompile += %w( potlatch2/locales/*.swf )
  config.assets.precompile += %w( help/introduction.* )
  config.assets.precompile += %w( iD.js iD.css )
  config.assets.precompile += %w( iD/img/*.svg iD/img/*.png iD/img/*.gif )
  config.assets.precompile += %w( iD/img/pattern/*.png )

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  # config.autoflush_log = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new
end
