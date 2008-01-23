# This file loads various yml configuration files

# Load application config
APP_CONFIG = YAML.load(File.read(RAILS_ROOT + "/config/application.yml"))[RAILS_ENV]
# This will let you more easily use helpers based on url_for in your mailers.
ActionMailer::Base.default_url_options[:host] = APP_CONFIG['host']

# Load texts in a particular language
TEXT = YAML.load(File.read(RAILS_ROOT + "/config/text_outputs/en.yml"))

