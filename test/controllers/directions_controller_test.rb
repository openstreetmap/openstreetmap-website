require "test_helper"

class DirectionsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/directions", :method => :get },
      { :controller => "directions", :action => "search" }
    )
  end

  ###
  # test the search action
  def test_search
    get directions_path
    assert_response :success
  end
end
