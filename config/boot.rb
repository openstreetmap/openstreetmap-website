ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" if ENV.fetch("ENABLE_BOOTSNAP", "true") == "true" # Speed up boot time by caching expensive operations.
