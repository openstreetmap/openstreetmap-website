require "test_helper"

class DirectionsControllerTest < ActionController::TestCase
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
    get :search
    assert_response :success
  end
end
