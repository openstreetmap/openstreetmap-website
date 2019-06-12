require "test_helper"
require "capybara/poltergeist"

# Work around weird debian/ubuntu phantomjs
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=817277
# https://github.com/ariya/phantomjs/issues/14376
ENV["QT_QPA_PLATFORM"] = "phantom" if IO.popen(["phantomjs", "--version"], :err => :close).read.empty?

ActiveSupport.on_load(:action_dispatch_system_test_case) do
  ActionDispatch::SystemTesting::Server.silence_puma = true
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :poltergeist, :screen_size => [1400, 1400]

  def initialize(*args)
    stub_request(:get, "https://api.hostip.info/country.php?ip=127.0.0.1")
      .to_return(:status => 404)
    super(*args)
  end

  # Phantomjs can pick up browser Accept-Language preferences from your desktop environment.
  # We don't want this to happen during the tests!
  setup do
    page.driver.add_headers("Accept-Language" => "en")
  end
end
