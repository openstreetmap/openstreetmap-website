source "https://rubygems.org"

# Core dependencies
gem "rails", "~> 7.2.0"
gem "turbo-rails"
gem "pg"  # PostgreSQL database
gem "json"  # Required for multi_json

# Asset management
gem "dartsass-sprockets"
gem "sass-embedded", "~> 1.64.0"
gem "terser"
gem "jquery-rails"

# API & JSON handling
gem "jbuilder", "~> 2.7"

# Performance optimizations
gem "bootsnap", ">= 1.4.2", require: false
gem "mini_racer", "~> 0.9.0"

# CSS & frontend utilities
gem "rtlcss"
gem "autoprefixer-rails"
gem "image_optim_rails"

# Security & authentication
gem "argon2"
gem "omniauth", "~> 2.0.2"
gem "omniauth-facebook"
gem "omniauth-github"
gem "omniauth-google-oauth2", ">= 0.6.0"
gem "omniauth-mediawiki", ">= 0.0.4"
gem "omniauth-microsoft_graph"
gem "omniauth-openid"
gem "omniauth-rails_csrf_protection", "~> 1.0"

# OAuth2 support
gem "doorkeeper"
gem "doorkeeper-i18n"
gem "doorkeeper-openid_connect"

# Database utilities
gem "activerecord-import"
gem "active_record_union"
gem "quad_tile", "~> 1.0.1"  # Native OSM extensions

# Web utilities
gem "rack-cors"
gem "rails-i18n", "~> 7.0.0"
gem "rails_param"
gem "strong_migrations", "< 2.0.0"

# HTML & text processing
gem "kramdown"  # Markdown formatting
gem "sanitize"  # Secure HTML sanitization
gem "htmlentities"
gem "rinku", ">= 2.0.6", require: "rails_rinku"

# HTTP & API handling
gem "faraday"
gem "http_accept_language", "~> 2.1.1"

# Geolocation
gem "maxminddb"

# Authentication & security
gem "rotp"  # TOTP token generation

# Caching & performance
gem "dalli"  # Memcache client
gem "connection_pool"

# Logging & monitoring
gem "logstasher"
gem "canonical-rails"  # SEO-friendly canonical URLs

# Image processing & storage
gem "aws-sdk-s3"
gem "image_processing"
gem "marcel"
gem "bzip2-ffi"
gem "ffi-libarchive"
gem "gd2-ffij", ">= 0.4.0"

# Development tools
group :development do
  gem "better_errors"
  gem "binding_of_caller"
  gem "debug_inspector"
  gem "i18n-tasks"
  gem "listen"
  gem "overcommit"
  gem "vendorer"
end

# Testing utilities
group :test do
  gem "brakeman"
  gem "capybara", ">= 2.15"
  gem "erb_lint", require: false
  gem "factory_bot_rails"
  gem "jwt"
  gem "minitest", "~> 5.1"
  gem "minitest-focus", require: false
  gem "puma", "~> 5.6"
  gem "rails-controller-testing"
  gem "rubocop"
  gem "rubocop-capybara"
  gem "rubocop-factory_bot"
  gem "rubocop-minitest"
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rake"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "simplecov-lcov", require: false
  gem "webmock"
end

# Shared development & test utilities
group :development, :test do
  gem "annotaterb"
  gem "teaspoon"
  gem "teaspoon-mocha", "~> 2.3.3"
  gem "debug", require: "debug/prelude"
end
