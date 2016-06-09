source "https://rubygems.org"

# Require rails
gem "rails", "4.2.6"

# Require things which have moved to gems in ruby 1.9
gem "bigdecimal", "~> 1.1.0", :platforms => :ruby_19

# Require things which have moved to gems in ruby 2.0
gem "psych", :platforms => :ruby_20

# Require json for multi_json
gem "json"

# Use postgres as the database
gem "pg"

# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use CoffeeScript for .js.coffee assets and views
gem "coffee-rails", "~> 4.1.0"

# Use jquery as the JavaScript library
gem "jquery-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.0'
gem "jsonify-rails"

# Use R2 for RTL conversion
gem "r2"

# Use autoprefixer to generate CSS prefixes
gem "autoprefixer-rails"

# Use image_optim to optimise images
gem "image_optim", ">= 0.22.0"

# Load rails plugins
gem "rails-i18n", "~> 4.0.0"
gem "dynamic_form"
gem "rinku", ">= 1.2.2", :require => "rails_rinku"
gem "oauth-plugin", ">= 0.5.1"
gem "validates_email_format_of", ">= 1.5.1"
gem "composite_primary_keys", "~> 8.1.0"
gem "http_accept_language", "~> 2.0.0"
gem "paperclip", "~> 4.0"
gem "deadlock_retry", ">= 1.2.0"
gem "i18n-js", ">= 3.0.0.rc10"
gem "rack-cors"
gem "actionpack-page_caching"

# Sanitise URIs
gem "rack-uri_sanitizer"

# Omniauth for authentication
gem "omniauth"
gem "omniauth-openid"
gem "omniauth-google-oauth2", ">= 0.2.7"
gem "omniauth-facebook"
gem "omniauth-windowslive"

# Markdown formatting support
gem "redcarpet"

# Load libxml support for XML parsing and generation
gem "libxml-ruby", ">= 2.0.5", :require => "libxml"

# Use for HTML sanitisation
gem "sanitize"
gem "htmlentities"

# Load SystemTimer for implementing request timeouts
gem "SystemTimer", ">= 1.1.3", :require => "system_timer", :platforms => :ruby_18

# Load faraday for mockable HTTP client
gem "faraday"

# Load httpclient and soap4r for SOAP support for Quova GeoIP queries
gem "httpclient"
gem "soap4r-ruby1.9"

# Load memcache client in case we are using it
gem "dalli"
gem "kgio"

# Used to generate logstash friendly log files
gem "logstasher"

# Used to keep out spam bots
gem "honeypot-captcha"

# Gems useful for development
group :development do
  gem "vendorer"
end

# Gems needed for running tests
group :test do
  gem "rubocop"
  gem "timecop"
  gem "minitest", "~> 5.1", :platforms => [:ruby_19, :ruby_20]
end

# Needed in development as well so rake can see konacha tasks
group :development, :test do
  gem "jshint"
  gem "konacha"
  gem "poltergeist"
  gem "coveralls", :require => false
end
