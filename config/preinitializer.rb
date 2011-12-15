require 'yaml'

config = YAML.load_file(File.expand_path("../application.yml", __FILE__))
env = ENV['RAILS_ENV'] || 'development'

ENV.each do |key,value|
  if key.match(/^OSM_(.*)$/)
    Object.const_set(Regexp.last_match(1).upcase, value)
  end
end

config[env].each do |key,value|
  unless Object.const_defined?(key.upcase)
    Object.const_set(key.upcase, value)
  end
end
