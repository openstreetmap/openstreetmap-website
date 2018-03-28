require "test_helper"
require "capybara/poltergeist"

WebMock.disable_net_connect!(:allow_localhost => true)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  ActionDispatch::SystemTesting::Server.silence_puma = true

  driven_by :poltergeist, :screen_size => [1400, 1400]

  def initialize(*args)
    stub_request(:get, "http://api.hostip.info/country.php?ip=127.0.0.1")
      .to_return(:status => 404)
    super(*args)
  end
end
