require "test_helper"

class CORSTest < ActionDispatch::IntegrationTest
  # Rails 4 adds a built-in `options` method. When we upgrade, we can remove
  # this definition.
  unless instance_methods.include?(:options)
    def options(*args)
      reset! unless integration_session
      @html_document = nil
      integration_session.send(:process, :options, *args).tap do
        copy_session_variables!
      end
    end
  end

  def test_api_routes_allow_cross_origin_requests
    options "/api/capabilities", nil,
            "HTTP_ORIGIN" => "http://www.example.com",
            "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET"

    assert_response :success
    assert_equal "http://www.example.com", response.headers["Access-Control-Allow-Origin"]
  end

  def test_non_api_routes_dont_allow_cross_origin_requests
    assert_raises ActionController::RoutingError do
      options "/", nil,
              "HTTP_ORIGIN" => "http://www.example.com",
              "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET"
    end
  end
end
