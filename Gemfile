source 'http://rubygems.org'

gem 'rails', '3.1.0'

gem 'pg'
gem 'arel', '>= 2.0.9'
gem 'libxml-ruby', '>= 2.0.5', :require => 'libxml'
gem 'rmagick', :require => 'RMagick'
gem 'oauth', '>= 0.4.4'
gem 'oauth-plugin', '>= 0.4.0.pre4'
gem 'httpclient'
gem 'SystemTimer', '>= 1.1.3', :require => 'system_timer'
gem 'sanitize'
gem 'rails-i18n-updater'
gem 'validates_email_format_of', '>= 1.5.1'
gem 'open_id_authentication', '>= 1.1.0'
gem 'prototype-rails'
gem 'rinku', '>= 1.2.2', :require => 'rails_rinku'
gem 'dynamic_form'

# Should only load if memcache is in use
#gem 'memcached'

# Should only load if we're not in database offline mode
gem 'composite_primary_keys', '= 4.0.0'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'timecop'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end
