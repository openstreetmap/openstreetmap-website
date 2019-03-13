require "yaml"

env = if defined?(Rake.application) && Rake.application.top_level_tasks.grep(/^(default$|test(:|$))/).any?
        "test"
      else
        ENV["RAILS_ENV"] || "development"
      end

config = YAML.load_file(File.expand_path(env == "test" ? "../example.application.yml" : "../application.yml", __FILE__))

config[env].each do |key, value|
  Object.const_set(key.upcase, value) unless Object.const_defined?(key.upcase)
end
