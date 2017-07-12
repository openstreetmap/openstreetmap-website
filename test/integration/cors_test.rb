require "test_helper"

class CORSTest < ActionDispatch::IntegrationTest
  def test_api_routes_allow_cross_origin_requests
    process :options, "/api/capabilities", :headers => {
      "HTTP_ORIGIN" => "http://www.example.com",
      "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET"
    }

    assert_response :success
    assert_equal "http://www.example.com", response.headers["Access-Control-Allow-Origin"]
  end

  def test_non_api_routes_dont_allow_cross_origin_requests
    assert_raises ActionController::RoutingError do
      process :options, "/", :headers => {
        "HTTP_ORIGIN" => "http://www.example.com",
        "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET"
      }
    end
  end
end
