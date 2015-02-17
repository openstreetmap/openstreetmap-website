require 'yaml'

if defined?(Rake.application) && Rake.application.top_level_tasks.grep(/^(default$|test(:|$))/).any?
  env = "test"
else
  env = ENV['RAILS_ENV'] || 'development'
end

config = YAML.load_file(File.expand_path(env == "test" ? "../example.application.yml" : "../application.yml", __FILE__))

ENV.each do |key, value|
  if key.match(/^OSM_(.*)$/)
    Object.const_set(Regexp.last_match(1).upcase, value)
  end
end

config[env].each do |key, value|
  Object.const_set(key.upcase, value) unless Object.const_defined?(key.upcase)
end
