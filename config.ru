# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

# TODO: Confirm that this is truly needed to fix rails routing for websites at a sub-path.
map ENV['RAILS_RELATIVE_URL_ROOT'] || "/" do
  run Rails.application
end
