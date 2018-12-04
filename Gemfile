source "https://rubygems.org"

# Require rails
gem "rails", "5.2.2"

# Require things which have moved to gems in ruby 1.9
gem "bigdecimal", "~> 1.1.0", :platforms => :ruby_19

# Require things which have moved to gems in ruby 2.0
gem "psych", :platforms => :ruby_20

# Require json for multi_json
gem "json"

# Use postgres as the database
gem "pg", "~> 0.18"

# Use SCSS for stylesheets
gem "sassc-rails"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use CoffeeScript for .js.coffee assets and views
gem "coffee-rails", "~> 4.2"

# Use jquery as the JavaScript library
gem "jquery-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.0'
gem "jsonify-rails"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", :require => false

# Use R2 for RTL conversion
gem "r2", "~> 0.2.7"

# Use autoprefixer to generate CSS prefixes
gem "autoprefixer-rails", "~> 8.6.3"

# Use image_optim to optimise images
gem "image_optim_rails"

# Load rails plugins
gem "actionpack-page_caching"
gem "active_record_union"
gem "cancancan"
gem "composite_primary_keys", "~> 11.1.0"
gem "delayed_job_active_record"
gem "dynamic_form"
gem "http_accept_language", "~> 2.0.0"
gem "i18n-js", ">= 3.0.0"
gem "oauth-plugin", ">= 0.5.1"
gem "openstreetmap-deadlock_retry", ">= 1.3.0", :require => "deadlock_retry"
gem "paperclip", "~> 5.2"
gem "rack-cors"
gem "rails-i18n", "~> 4.0.0"
gem "record_tag_helper"
gem "rinku", ">= 1.2.2", :require => "rails_rinku"
gem "validates_email_format_of", ">= 1.5.1"

# Native OSM extensions
gem "quad_tile", "~> 1.0.1"

# Sanitise URIs
gem "rack-uri_sanitizer"

# Omniauth for authentication
gem "omniauth"
gem "omniauth-facebook"
gem "omniauth-github"
gem "omniauth-google-oauth2", ">= 0.2.7"
gem "omniauth-mediawiki", ">= 0.0.3"
gem "omniauth-openid"
gem "omniauth-windowslive"

# Markdown formatting support
gem "redcarpet"

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

# Load geoip for querying Maxmind GeoIP database
gem "geoip"

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
  gem "minitest", "~> 5.1", :platforms => [:ruby_19, :ruby_20]
  gem "rails-controller-testing"
  gem "rubocop"
  gem "webmock"
end

# Needed in development as well so rake can see konacha tasks
group :development, :test do
  gem "capybara", "~> 2.13"
  gem "coveralls", :require => false
  gem "factory_bot_rails"
  gem "jshint"
  gem "poltergeist"
  gem "puma", "~> 3.7"
end
