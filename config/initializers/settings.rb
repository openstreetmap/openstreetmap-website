# This is our custom setup for using application.yml for configuration setup
# Hopefully it can be removed when we move to using standard Config gem configuration files
# or if the Config gem ever supports custom paths during initial setup.

env = if defined?(Rake.application) && Rake.application.top_level_tasks.grep(/^(default$|test(:|$))/).any?
        "test"
      else
        ENV["RAILS_ENV"] || "development"
      end

conf = YAML.load_file(Rails.root.join("config", (env == "test" ? "example.application.yml" : "application.yml")))

# Pass in the correct yaml for the environment
Settings.prepend_source!(conf[env])

# Now set up our schema validations
Config.schema do
  required(:api_version).filled(:str?)
  required(:max_request_area).filled(:number?)
  required(:max_note_request_area).filled(:number?)
  required(:tracepoints_per_page).filled(:int?)
  required(:max_number_of_way_nodes).filled(:int?)
  required(:api_timeout).filled(:int?)
  required(:imagery_blacklist).maybe(:array?)
end

Settings.reload!
