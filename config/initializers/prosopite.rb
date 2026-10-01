# frozen_string_literal: true

# Fail tests on N+1 queries, apart from those with any of the files listed
# in test/prosopite_todo.yml in their call stack. That list should only
# ever shrink. Each of these is scanned separately:
#
#  * requests, whether made by ActionDispatch::IntegrationTest subclasses
#    (which includes the tests in test/controllers as well as
#    test/integration) or by the browser in system tests
#  * jobs performed by any test (see test/test_helper.rb)
#
# Test setup, such as creating records with factories, isn't scanned.
if Rails.env.test?
  require "prosopite/middleware/rack"
  Rails.application.config.middleware.use(Prosopite::Middleware::Rack)

  Prosopite.raise = true
  Prosopite.allow_stack_paths = YAML.load_file(Rails.root.join("test/prosopite_todo.yml")).map do |path|
    # Match "/app/models/way.rb:123" but not "/app/models/old_way.rb:123"
    "/#{path}:"
  end
end
