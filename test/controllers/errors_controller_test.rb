require "test_helper"

class ErrorsControllerTest < ActionController::TestCase
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
    get :forbidden
    assert_response :forbidden
  end

  def test_not_found
    get :not_found
    assert_response :not_found
  end

  def test_internal_server_error
    get :internal_server_error
    assert_response :internal_server_error
  end
end
