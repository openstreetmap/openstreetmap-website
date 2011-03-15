source 'http://rubygems.org'

gem 'rails', '3.0.5'

gem 'pg'
gem 'arel', '>= 2.0.9'
gem 'libxml-ruby', '>= 2.0.5', :require => 'libxml'
gem 'rmagick', :require => 'RMagick'
gem 'oauth', '>= 0.4.4'
gem 'oauth-plugin', '> 0.3.14'
gem 'httpclient'
gem 'SystemTimer', '>= 1.1.3', :require => 'system_timer'
gem 'sanitize'
gem 'rails-i18n-updater'
gem 'validates_email_format_of', '>= 1.4.5'

# Should only load if memcache is in use
gem 'memcached'

# Should only load if we're not in database offline mode
gem 'composite_primary_keys', '>= 3.1.4'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'timecop'
end
