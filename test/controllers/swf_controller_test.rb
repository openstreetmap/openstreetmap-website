require "test_helper"

class SwfControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/swf/trackpoints", :method => :get },
      { :controller => "swf", :action => "trackpoints" }
    )
  end
end
