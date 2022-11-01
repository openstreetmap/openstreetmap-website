source "https://rubygems.org"

# Require rails
gem "rails", "7.0.4"

# Require json for multi_json
gem "json"

# Use postgres as the database
gem "pg"

# Use SCSS for stylesheets
gem "sassc-rails"

# Use Terser as compressor for JavaScript assets
gem "terser"

# Use jquery as the JavaScript library
gem "jquery-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", :require => false

# Use R2 for RTL conversion
gem "r2", "~> 0.2.7"

# Use autoprefixer to generate CSS prefixes
gem "autoprefixer-rails"

# Use image_optim to optimise images
gem "image_optim_rails"

# Use argon2 for password hashing
gem "argon2"

# Support brotli compression for assets
gem "sprockets-exporters_pack"

# Load rails plugins
gem "actionpack-page_caching", ">= 1.2.0"
gem "activerecord-import"
gem "active_record_union"
gem "bootstrap", "~> 5.1.0"
gem "bootstrap_form", "~> 5.0"
gem "cancancan"
gem "composite_primary_keys", "~> 14.0.0"
gem "config"
gem "delayed_job_active_record"
gem "http_accept_language", "~> 2.1.1"
gem "i18n-js", "~> 3.9.2"
gem "oauth-plugin", ">= 0.5.1"
gem "openstreetmap-deadlock_retry", ">= 1.3.1", :require => "deadlock_retry"
gem "rack-cors"
gem "rails-i18n", "~> 7.0.0"
gem "rinku", ">= 2.0.6", :require => "rails_rinku"
gem "strong_migrations"
gem "validates_email_format_of", ">= 1.5.1"

# Native OSM extensions
gem "quad_tile", "~> 1.0.1"

# Sanitise URIs
gem "rack-uri_sanitizer"

# Omniauth for authentication
gem "omniauth", "~> 2.0.2"
gem "omniauth-facebook"
gem "omniauth-github"
gem "omniauth-google-oauth2", ">= 0.6.0"
gem "omniauth-mediawiki", ">= 0.0.4"
gem "omniauth-openid"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-windowslive"

# Doorkeeper for OAuth2
gem "doorkeeper"
gem "doorkeeper-i18n"

# Markdown formatting support
gem "kramdown"

# For status transitions of Issues
gem "aasm"

# Load libxml support for XML parsing and generation
gem "libxml-ruby", ">= 2.0.5", :require => "libxml"

# Use for HTML sanitisation
gem "htmlentities"
gem "sanitize"

# Load faraday for mockable HTTP client
gem "faraday"

# Load maxminddb for querying Maxmind GeoIP database
gem "maxminddb"

# Load rotp to generate TOTP tokens
gem "rotp"

# Load memcache client in case we are using it
gem "connection_pool"
gem "dalli"
gem "kgio"

# Load secure_headers for Content-Security-Policy support
gem "secure_headers"

# Load canonical-rails to generate canonical URLs
gem "canonical-rails"

# Used to generate logstash friendly log files
gem "logstasher"

# Used to generate images for traces
gem "bzip2-ffi"
gem "ffi-libarchive"
gem "gd2-ffij", ">= 0.4.0"
gem "marcel"

# Used for browser detection
gem "browser"

# Used for S3 object storage
gem "aws-sdk-s3"

# Used to resize user images
gem "image_processing"

# Gems useful for development
group :development do
  gem "annotate"
  gem "better_errors"
  gem "binding_of_caller"
  gem "debug_inspector"
  gem "listen"
  gem "vendorer"
end

# Gems needed for running tests
group :test do
  gem "brakeman"
  gem "capybara", ">= 2.15"
  gem "erb_lint", :require => false
  gem "factory_bot_rails"
  gem "minitest", "~> 5.1"
  gem "puma", "~> 5.6"
  gem "rails-controller-testing"
  gem "rubocop"
  gem "rubocop-minitest"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rake"
  gem "selenium-webdriver"
  gem "simplecov", :require => false
  gem "simplecov-lcov", :require => false
  gem "webmock"
end
