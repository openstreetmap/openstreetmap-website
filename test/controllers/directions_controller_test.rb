require "test_helper"

class DirectionsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/directions", :method => :get },
      { :controller => "directions", :action => "show" }
    )
  end

  def test_show
    get directions_path
    assert_response :success
  end
end
