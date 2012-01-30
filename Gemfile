# Gem source to use
source 'http://rubygems.org'

# Require rails
gem 'rails', '3.1.3'

# Require the postgres database driver
gem 'pg'

# Load jquery support
gem 'jquery-rails'

# Load rails plugins
gem 'rails-i18n-updater'
gem 'dynamic_form'
gem 'rinku', '>= 1.2.2', :require => 'rails_rinku'
gem 'oauth-plugin', '>= 0.4.0.pre7'
gem 'open_id_authentication', '>= 1.1.0'
gem 'validates_email_format_of', '>= 1.5.1'
gem 'composite_primary_keys', '>= 4.1.2'

# Character conversion support for ruby 1.8
gem 'iconv', :platforms => :ruby_18

# Load libxml support for XML parsing and generation
gem 'libxml-ruby', '>= 2.0.5', :require => 'libxml'

# Load ImageMagick support for user picture resizing
gem 'rmagick', :require => 'RMagick'

# Load HTML sanitizer
gem 'sanitize'

# Load SystemTimer for implementing request timeouts
gem 'SystemTimer', '>= 1.1.3', :require => 'system_timer', :platforms => :ruby_18

# Load httpclient for SOAP support for Quova GeoIP queries
gem 'httpclient'

# Load memcache in case we are using it
gem 'memcache-client'
gem 'memcached'

# Gems needed for running tests
group :test do
  gem 'timecop'
end

# Gems needed for compiling assets
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
  gem 'therubyracer'
end
