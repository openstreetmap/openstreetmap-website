require "test_helper"

class CORSTest < ActionDispatch::IntegrationTest
  def test_api_routes_allow_cross_origin_requests
    process :options, "/api/capabilities", :headers => {
      "HTTP_ORIGIN" => "http://www.example.com",
      "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET"
    }

    assert_response :success
    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
    assert_equal "text/plain", response.content_type
    assert_equal "", response.body
  end

  def test_non_api_routes_dont_allow_cross_origin_requests
    process :options, "/", :headers => {
      "HTTP_ORIGIN" => "http://www.example.com",
      "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET"
    }

    assert_response :success
    assert_nil response.headers["Access-Control-Allow-Origin"]
    assert_nil response.content_type
    assert_equal "", response.body
  end
end
