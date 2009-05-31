# This file loads various yml configuration files

# Load application config
APP_CONFIG = YAML.load(File.read(RAILS_ROOT + "/config/application.yml"))[RAILS_ENV]
