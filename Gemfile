source "https://rubygems.org"

# Require rails
gem "rails", "6.0.2.2"

# Require things which have moved to gems in ruby 1.9
gem "bigdecimal", "~> 1.1.0", :platforms => :ruby_19

# Require things which have moved to gems in ruby 2.0
gem "psych", :platforms => :ruby_20

# Require json for multi_json
gem "json"

# Use postgres as the database
gem "pg"

# Use SCSS for stylesheets
gem "sassc-rails"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

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

# Load rails plugins
gem "actionpack-page_caching", ">= 1.2.0"
gem "active_record_union"
gem "activerecord-import"
gem "bootstrap", "~> 4.3.1"
gem "cancancan"
gem "composite_primary_keys", "~> 12.0.0"
gem "config"
gem "delayed_job_active_record"
gem "dynamic_form"
gem "http_accept_language", "~> 2.0.0"
gem "i18n-js", ">= 3.0.0"
gem "oauth-plugin", ">= 0.5.1"
gem "openstreetmap-deadlock_retry", ">= 1.3.0", :require => "deadlock_retry"
gem "rack-cors"
gem "rails-i18n", "~> 4.0.0"
gem "rinku", ">= 2.0.6", :require => "rails_rinku"
gem "strong_migrations"
gem "validates_email_format_of", ">= 1.5.1"

# Native OSM extensions
gem "quad_tile", "~> 1.0.1"

# Sanitise URIs
gem "rack-uri_sanitizer"

# Omniauth for authentication
gem "omniauth"
gem "omniauth-facebook"
gem "omniauth-github"
gem "omniauth-google-oauth2", ">= 0.6.0"
gem "omniauth-mediawiki", ">= 0.0.4"
gem "omniauth-openid"
gem "omniauth-windowslive"

# Markdown formatting support
gem "kramdown"

# For status transitions of Issues
gem "aasm"

# Load libxml support for XML parsing and generation
gem "libxml-ruby", ">= 2.0.5", :require => "libxml"

# Use for HTML sanitisation
gem "htmlentities"
gem "sanitize"

# Load SystemTimer for implementing request timeouts
gem "SystemTimer", ">= 1.1.3", :require => "system_timer", :platforms => :ruby_18

# Load faraday for mockable HTTP client
gem "faraday"

# Load maxminddb for querying Maxmind GeoIP database
gem "maxminddb"

# Load rotp to generate TOTP tokens
gem "rotp"

# Load memcache client in case we are using it
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
gem "mimemagic"

# Used for browser detection
gem "browser"

# Used for S3 object storage
gem "aws-sdk-s3"

# Used to resize user images
gem "mini_magick"

# Gems useful for development
group :development do
  gem "annotate"
  gem "better_errors"
  gem "binding_of_caller"
  gem "listen"
  gem "vendorer"
end

# Gems needed for running tests
group :test do
  gem "capybara", ">= 2.15"
  gem "coveralls", :require => false
  gem "erb_lint", :require => false
  gem "factory_bot_rails"
  gem "minitest", "~> 5.1"
  gem "puma", "~> 3.11"
  gem "rails-controller-testing"
  gem "rubocop"
  gem "rubocop-minitest"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "selenium-webdriver"
  gem "webmock"
end
