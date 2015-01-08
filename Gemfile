source 'https://rubygems.org'

# Require rails
gem 'rails', '4.1.9'

# Require things which have moved to gems in ruby 1.9
gem 'bigdecimal', "~> 1.1.0", :platforms => :ruby_19

# Require things which have moved to gems in ruby 2.0
gem 'psych', :platforms => :ruby_20

# Require json for multi_json
gem 'json'

# Use postgres as the database
gem 'pg'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 1.2'
gem 'jsonify-rails'

# Use R2 for RTL conversion
gem 'r2'

# Use autoprefixer to generate CSS prefixes
gem 'autoprefixer-rails'

# Load rails plugins
gem 'rails-i18n', "~> 4.0.0"
gem 'dynamic_form'
gem 'rinku', '>= 1.2.2', :require => 'rails_rinku'
gem 'oauth-plugin', '>= 0.5.1'
gem 'open_id_authentication', '>= 1.1.0'
gem 'validates_email_format_of', '>= 1.5.1'
gem 'composite_primary_keys', '~> 7.0.11'
gem 'http_accept_language', '~> 2.0.0'
gem 'paperclip', '~> 4.0'
gem 'deadlock_retry', '>= 1.2.0'
gem 'openstreetmap-i18n-js', '>= 3.0.0.rc5.3', :require => 'i18n-js'
gem 'rack-cors'
gem 'actionpack-page_caching'

# We need ruby-openid 2.2.0 or later for ruby 1.9 support
gem 'ruby-openid', '>= 2.2.0'

# Markdown formatting support
gem 'redcarpet'

# Character conversion support for ruby 1.8
gem 'iconv', '= 0.1', :platforms => :ruby_18

# Load libxml support for XML parsing and generation
gem 'libxml-ruby', '>= 2.0.5', :require => 'libxml'

# Use for HTML sanitisation
gem 'sanitize'
gem 'htmlentities'

# Load SystemTimer for implementing request timeouts
gem 'SystemTimer', '>= 1.1.3', :require => 'system_timer', :platforms => :ruby_18

# Load httpclient and soap4r for SOAP support for Quova GeoIP queries
gem 'httpclient'
gem 'soap4r-ruby1.9'

# Load memcache client in case we are using it
gem 'dalli'
gem 'kgio'

# Gems useful for development
group :development do
  gem 'vendorer'
end

# Gems needed for running tests
group :test do
  gem 'timecop'
  gem 'minitest', '~> 5.1', :platforms => [:ruby_19, :ruby_20]
end

# Needed in development as well so rake can see konacha tasks
group :development, :test do
  gem 'konacha'
  gem 'poltergeist'
end
