require "test_helper"

class NominatimTest < ActiveSupport::TestCase
  def test_describe_location
    stub_request(:get, %r{^https://nominatim\.example\.com/reverse\?})
      .to_return(:body => "<reversegeocode><result>Target location</result></reversegeocode>")

    with_settings(:nominatim_url => "https://nominatim.example.com/") do
      location = Nominatim.describe_location(60, 30, 10, "en")
      assert_equal "Target location", location
    end

    assert_requested :get, "https://nominatim.example.com/reverse?lat=60&lon=30&zoom=10&accept-language=en",
                     :headers => { "User-Agent" => Settings.server_url }
  end

  def test_describe_location_no_result
    stub_request(:get, %r{^https://nominatim\.example\.com/reverse\?})
      .to_return(:body => "<reversegeocode><error>Unable to geocode</error></reversegeocode>")

    with_settings(:nominatim_url => "https://nominatim.example.com/") do
      location = Nominatim.describe_location(1, 2, 14, "en")
      assert_equal "1.000, 2.000", location
    end

    assert_requested :get, "https://nominatim.example.com/reverse?lat=1&lon=2&zoom=14&accept-language=en",
                     :headers => { "User-Agent" => Settings.server_url }
  end
end
