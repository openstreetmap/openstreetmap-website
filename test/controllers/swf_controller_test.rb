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

  ##
  # basic test that trackpoints at least returns some sort of flash movie
  def test_trackpoints
    get :trackpoints, :xmin => 51, :xmax => 52, :ymin => -1, :ymax => 1, :baselong => 0, :basey => 0, :masterscale => 1
    assert_response :success
    assert_equal "application/x-shockwave-flash", response.content_type
    assert_match /^FWS/, response.body
  end
end
