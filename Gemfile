# Gem source to use
source 'http://rubygems.org'

# Require rails
gem 'rails', '3.2.8'

# Require things which have moved to gems in ruby 1.9
gem 'bigdecimal', :platforms => :ruby_19

# Require the postgres database driver
gem 'pg'

# Load jquery support
gem 'jquery-rails'

# Load rails plugins
gem 'rails-i18n', ">= 0.6.3"
gem 'dynamic_form'
gem 'rinku', '>= 1.2.2', :require => 'rails_rinku'
gem 'oauth-plugin', '>= 0.4.1', :require => 'oauth-plugin'
gem 'open_id_authentication', '>= 1.1.0'
gem 'validates_email_format_of', '>= 1.5.1'
gem 'composite_primary_keys', '>= 5.0.9'
gem 'http_accept_language', '>= 1.0.2'
gem 'paperclip', '~> 2.0'
gem 'deadlock_retry', '>= 1.2.0'
gem 'i18n-js', '>= 3.0.0.rc2'

# We need ruby-openid 2.2.0 or later for ruby 1.9 support
gem 'ruby-openid', '>= 2.2.0'

# Markdown formatting support
gem 'redcarpet'

# Character conversion support for ruby 1.8
gem 'iconv', :platforms => :ruby_18

# Load libxml support for XML parsing and generation
gem 'libxml-ruby', '>= 2.0.5', :require => 'libxml'

# Use for HTML sanitisation
gem 'sanitize'
gem 'htmlentities'

# Load SystemTimer for implementing request timeouts
gem 'SystemTimer', '>= 1.1.3', :require => 'system_timer', :platforms => :ruby_18

# Load httpclient for SOAP support for Quova GeoIP queries
gem 'httpclient'

# Load memcache in case we are using it
gem 'memcached', '>= 1.4.1'

# Gems needed for running tests
group :test do
  gem 'timecop'
  gem 'minitest', :platforms => :ruby_19
end

# Gems needed for compiling assets
group :assets do
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'therubyracer'
  gem 'ejs'
end
