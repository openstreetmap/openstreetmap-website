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
    user = create(:user)
    other_user = create(:user)
    create(:trace, :visibility => "trackable", :latitude => 51.51, :longitude => -0.14, :user => user) do |trace|
      create(:tracepoint, :trace => trace, :trackid => 1, :latitude => (51.510 * GeoRecord::SCALE).to_i, :longitude => (-0.140 * GeoRecord::SCALE).to_i)
      create(:tracepoint, :trace => trace, :trackid => 2, :latitude => (51.511 * GeoRecord::SCALE).to_i, :longitude => (-0.141 * GeoRecord::SCALE).to_i)
    end
    create(:trace, :visibility => "identifiable", :latitude => 51.512, :longitude => 0.142) do |trace|
      create(:tracepoint, :trace => trace, :latitude => (51.512 * GeoRecord::SCALE).to_i, :longitude => (0.142 * GeoRecord::SCALE).to_i)
    end

    get :trackpoints, :xmin => -1, :xmax => 1, :ymin => 51, :ymax => 52, :baselong => 0, :basey => 0, :masterscale => 1
    assert_response :success
    assert_equal "application/x-shockwave-flash", response.content_type
    assert_match /^FWS/, response.body
    assert_equal 80, response.body.length

    get :trackpoints, :xmin => -1, :xmax => 1, :ymin => 51, :ymax => 52, :baselong => 0, :basey => 0, :masterscale => 1, :token => other_user.tokens.create.token
    assert_response :success
    assert_equal "application/x-shockwave-flash", response.content_type
    assert_match /^FWS/, response.body
    assert_equal 67, response.body.length

    get :trackpoints, :xmin => -1, :xmax => 1, :ymin => 51, :ymax => 52, :baselong => 0, :basey => 0, :masterscale => 1, :token => user.tokens.create.token
    assert_response :success
    assert_equal "application/x-shockwave-flash", response.content_type
    assert_match /^FWS/, response.body
    assert_equal 74, response.body.length
  end
end
