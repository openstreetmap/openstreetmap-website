require "test_helper"

class SwfControllerTest < ActionController::TestCase
  api_fixtures

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
    get :trackpoints, :xmin => -1, :xmax => 1, :ymin => 51, :ymax => 52, :baselong => 0, :basey => 0, :masterscale => 1
    assert_response :success
    assert_equal "application/x-shockwave-flash", response.content_type
    assert_match /^FWS/, response.body
    assert_equal 80, response.body.length

    get :trackpoints, :xmin => -1, :xmax => 1, :ymin => 51, :ymax => 52, :baselong => 0, :basey => 0, :masterscale => 1, :token => users(:normal_user).tokens.create.token
    assert_response :success
    assert_equal "application/x-shockwave-flash", response.content_type
    assert_match /^FWS/, response.body
    assert_equal 67, response.body.length

    get :trackpoints, :xmin => -1, :xmax => 1, :ymin => 51, :ymax => 52, :baselong => 0, :basey => 0, :masterscale => 1, :token => users(:public_user).tokens.create.token
    assert_response :success
    assert_equal "application/x-shockwave-flash", response.content_type
    assert_match /^FWS/, response.body
    assert_equal 74, response.body.length
  end
end
