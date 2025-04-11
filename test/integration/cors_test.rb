require "test_helper"

class CORSTest < ActionDispatch::IntegrationTest
  def test_api_routes_allow_cross_origin_requests
    process :options, "/api/capabilities", :headers => {
      "Origin" => "http://www.example.com",
      "Access-Control-Request-Method" => "GET"
    }

    assert_response :success
    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
    assert_nil response.media_type
    assert_equal "", response.body
  end

  def test_non_api_routes_dont_allow_cross_origin_requests
    process :options, "/", :headers => {
      "Origin" => "http://www.example.com",
      "Access-Control-Request-Method" => "GET"
    }

    assert_response :success
    assert_nil response.headers["Access-Control-Allow-Origin"]
    assert_nil response.media_type
    assert_equal "", response.body
  end
end
