require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/403", :method => :get },
      { :controller => "errors", :action => "forbidden" }
    )
    assert_routing(
      { :path => "/404", :method => :get },
      { :controller => "errors", :action => "not_found" }
    )
    assert_routing(
      { :path => "/500", :method => :get },
      { :controller => "errors", :action => "internal_server_error" }
    )
  end

  def test_forbidden
    get "/403"
    assert_response :forbidden
  end

  def test_not_found
    get "/404"
    assert_response :not_found
  end

  def test_internal_server_error
    get "/500"
    assert_response :internal_server_error
  end
end
