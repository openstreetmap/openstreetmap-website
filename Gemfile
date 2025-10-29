# frozen_string_literal: true

source "https://rubygems.org"

# Require rails
gem "rails", "~> 8.1.0"
gem "turbo-rails"

# Use postgres as the database
gem "pg"

# Use SCSS for stylesheets
gem "dartsass-sprockets"
# Pin the dependentent sass-embedded to avoid deprecation warnings in bootstrap
gem "sass-embedded", "~> 1.64.0"
# Pin uri to avoid errors in dartsass-ruby
gem "uri", "< 1.0.0"

# Use Terser as compressor for JavaScript assets
gem "terser"

# Use jquery as the JavaScript library
gem "jquery-rails"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.2", :require => false

# Use rtlcss for RTL conversion
gem "mini_racer", "~> 0.9.0"
gem "rtlcss"

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
gem "bootstrap", "~> 5.3.2"
gem "bootstrap_form", "~> 5.0"
gem "cancancan"
gem "config"
gem "delayed_job_active_record"
gem "dry-validation"
gem "frozen_record"
gem "http_accept_language", "~> 2.1.1"
gem "i18n-js", "~> 4.2.3"
gem "openstreetmap-deadlock_retry", ">= 1.3.1", :require => "deadlock_retry"
gem "rack-cors"
gem "rails-i18n", "~> 8.0.0"
gem "rails_param"
gem "rinku", ">= 2.0.6", :require => "rails_rinku"
gem "strong_migrations"
gem "validates_email_format_of", ">= 1.5.1"

# Native OSM extensions
gem "quad_tile", "~> 1.0.1"

# Sanitise URIs
gem "addressable", "~> 2.8"
gem "rack-uri_sanitizer"

gem "omniauth", "~> 2.1.3"
gem "omniauth-apple"
gem "omniauth-facebook"
gem "omniauth-github"
gem "omniauth-google-oauth2", ">= 0.6.0"
gem "omniauth-mediawiki", ">= 0.0.4"
gem "omniauth-microsoft_graph"
gem "omniauth-rails_csrf_protection", "~> 1.0"

# Doorkeeper for OAuth2
gem "doorkeeper"
gem "doorkeeper-i18n"
gem "doorkeeper-openid_connect"

# Markdown formatting support
gem "kramdown"

# For status transitions of Issues
gem "aasm"

# XML parsing and generation
gem "libxml-ruby", ">= 2.0.5"
gem "rexml"

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

# Load canonical-rails to generate canonical URLs
gem "canonical-rails", :github => "commonlit/canonical-rails", :ref => "bump-rails-8-1"

# Use to generate telemetry
gem "opentelemetry-exporter-otlp", :require => false
gem "opentelemetry-instrumentation-all", :require => false
gem "opentelemetry-sdk", :require => false

# Used to generate images for traces
gem "bzip2-ffi"
gem "ffi-libarchive"
# Use https://github.com/dark-panda/gd2-ffij/pull/28 for Docker/macOS compatibility
gem "gd2-ffij", :github => "rkoeze/gd2-ffij", :ref => "a203a8d5ef004a4198950e86329228fe3f331d06"
gem "marcel"

# Used for S3 object storage
gem "aws-sdk-s3"

# Used to resize user images
gem "image_processing"

# Used to manage svg files
gem "inline_svg"

# Used to validate widths
gem "unicode-display_width"

# Stop when running for too long
gem "timeout"

# To run the `file` command and read the output
gem "open3"

# Cryptographic tools
gem "digest"

# Gems useful for development
group :development do
  gem "better_errors"
  gem "binding_of_caller"
  gem "danger"
  gem "danger-auto_label"
  gem "debug_inspector"
  gem "i18n-tasks"
  gem "listen"
  gem "overcommit"
  gem "vendorer"
end

# Gems needed for running tests
group :test do
  gem "brakeman"
  gem "capybara", ">= 2.15"
  gem "erb_lint", :require => false
  gem "factory_bot_rails"
  gem "jwt"
  gem "minitest"
  gem "minitest-focus", :require => false
  gem "puma", "~> 6.6"
  gem "rails-controller-testing"
  gem "rubocop"
  gem "rubocop-capybara"
  gem "rubocop-factory_bot"
  gem "rubocop-minitest"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rake"
  gem "selenium-webdriver"
  gem "simplecov", :require => false
  gem "simplecov-lcov", :require => false
  gem "webmock"
end

group :development, :test do
  gem "annotaterb"
  gem "rackup"
  gem "teaspoon"
  gem "teaspoon-mocha", "~> 2.3.3"
  gem "webrick"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", :require => "debug/prelude"
end
