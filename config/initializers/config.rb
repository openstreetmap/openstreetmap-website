# Guard against deployments with old-style application.yml configurations
# Otherwise, admins might not be aware that they are now silently ignored
# and major problems could occur
# rubocop:disable Rails/Output, Rails/Exit
if Rails.root.join("config/application.yml").exist?
  puts "The config/application.yml file is no longer supported."
  puts ""
  puts "Default settings are now found in config/settings.yml and you"
  puts "can override these in config/settings.local.yml."
  puts ""
  puts "To prevent unexpected behaviour, please copy any custom"
  puts "settings to config/settings.local.yml and then remove"
  puts "your config/application.yml file."
  exit!
end
# rubocop:enable Rails/Output, Rails/Exit

# Allowed status values
ALLOWED_STATUS = [
  "online",            # online and operating normally
  "api_readonly",      # site online but API in read-only mode
  "api_offline",       # site online but API offline
  "database_readonly", # database and site in read-only mode
  "database_offline",  # database offline with site in emergency mode
  "gpx_offline"        # gpx storage offline
].freeze

Config.setup do |config|
  # Name of the constant exposing loaded settings
  config.const_name = "Settings"

  # Ability to remove elements of the array set in earlier loaded settings file. For example value: '--'.
  #
  # config.knockout_prefix = nil

  # Overwrite an existing value when merging a `nil` value.
  # When set to `false`, the existing value is retained after merge.
  #
  # config.merge_nil_values = true

  # Overwrite arrays found in previously loaded settings file. When set to `false`, arrays will be merged.
  #
  # config.overwrite_arrays = true

  # Load environment variables from the `ENV` object and override any settings defined in files.
  #
  config.use_env = true

  # Define ENV variable prefix deciding which variables to load into config.
  #
  config.env_prefix = "OPENSTREETMAP"

  # What string to use as level separator for settings loaded from ENV variables. Default value of '.' works well
  # with Heroku, but you might want to change it for example for '__' to easy override settings from command line, where
  # using dots in variable names might not be allowed (eg. Bash).
  #
  config.env_separator = "_"

  # Ability to process variables names:
  #   * nil  - no change
  #   * :downcase - convert to lower case
  #
  config.env_converter = :downcase

  # Parse numeric values as integers instead of strings.
  #
  # config.env_parse_values = true

  # Validate presence and type of specific config values. Check https://github.com/dry-rb/dry-validation for details.
  #
  config.schema do
    required(:api_version).filled(:str?)
    required(:max_request_area).filled(:number?)
    required(:max_note_request_area).filled(:number?)
    required(:tracepoints_per_page).filled(:int?)
    required(:max_number_of_way_nodes).filled(:int?)
    required(:max_number_of_relation_members).filled(:int?)
    required(:api_timeout).filled(:int?)
    required(:imagery_blacklist).maybe(:array?)
    required(:status).filled(:str?, :included_in? => ALLOWED_STATUS)
    required(:avatar_storage).filled(:str?)
    required(:trace_file_storage).filled(:str?)
    required(:trace_image_storage).filled(:str?)
    required(:trace_icon_storage).filled(:str?)
  end
end
