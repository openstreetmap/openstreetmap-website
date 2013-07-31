require 'yaml'

env = ENV['RAILS_ENV'] || 'development'
config = YAML.load_file(File.expand_path(env == "test" ? "../example.application.yml" : "../application.yml", __FILE__))

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
