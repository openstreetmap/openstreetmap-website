require File.dirname(__FILE__) + '/../test_helper'
require 'way_controller'

# Re-raise errors caught by the controller.
class WayController; def rescue_action(e) raise e end; end

class WayControllerTest < Test::Unit::TestCase
  fixtures :current_nodes, :nodes, :users, :current_segments, :segments, :ways, :current_ways, :way_tags, :current_way_tags, :way_segments, :current_way_segments
  set_fixture_class :current_ways => :Way
  set_fixture_class :ways => :OldWay
  set_fixture_class :current_segments => :Segment
  set_fixture_class :segments => :OldSegment

  def setup
    @controller = WayController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c
  end

  # -------------------------------------
  # Test reading ways.
  # -------------------------------------

  def test_read
    # check that a visible way is returned properly
    get :read, :id => current_ways(:visible_way).id
    assert_response :success

    # check that an invisible way is not returned
    get :read, :id => current_ways(:invisible_way).id
    assert_response :gone

    # check chat a non-existent way is not returned
    get :read, :id => 0
    assert_response :not_found
  end

  # -------------------------------------
  # Test simple way creation.
  # -------------------------------------

  def test_create
    sid = current_segments(:used_segment).id
    basic_authorization "test@openstreetmap.org", "test"

    # create a way with pre-existing segment
    content "<osm><way><seg id='#{sid}'/><tag k='test' v='yes' /></way></osm>"
    put :create
    # hope for success
    assert_response :success, 
        "way upload did not return success status"
    # read id of created way and search for it
    wayid = @response.body
    checkway = Way.find(wayid)
    assert_not_nil checkway, 
        "uploaded way not found in data base after upload"
    # compare values
    assert_equal checkway.segs.length, 1, 
        "saved way does not contain exactly one segment"
    assert_equal checkway.segs[0], sid, 
        "saved way does not contain the right segment"
    assert_equal users(:normal_user).id, checkway.user_id, 
        "saved way does not belong to user that created it"
    assert_equal true, checkway.visible, 
        "saved way is not visible"
  end

  # -------------------------------------
  # Test creating some invalid ways.
  # -------------------------------------

  def test_create_invalid
    basic_authorization "test@openstreetmap.org", "test"

    # create a way with non-existing segment
    content "<osm><way><seg id='0'/><tag k='test' v='yes' /></way></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "way upload with invalid segment did not return 'precondition failed'"

    # create a way with no segments
    content "<osm><way><tag k='test' v='yes' /></way></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "way upload with no segments did not return 'precondition failed'"

    # create a way that has the same segment, twice
    # (commented out - this is currently allowed!)
    #sid = current_segments(:used_segment).id
    #content "<osm><way><seg id='#{sid}'/><seg id='#{sid}'/><tag k='test' v='yes' /></way></osm>"
    #put :create
    #assert_response :internal_server_error,
    #    "way upload with double segment did not return 'internal server error'"
  end

  # -------------------------------------
  # Test deleting ways.
  # -------------------------------------
  
  def test_delete

    # first try to delete way without auth
    delete :delete, :id => current_ways(:visible_way).id
    assert_response :unauthorized

    # now set auth
    basic_authorization("test@openstreetmap.org", "test");  

    # this should work
    delete :delete, :id => current_ways(:visible_way).id
    assert_response :success

    # this won't work since the way is already deleted
    delete :delete, :id => current_ways(:invisible_way).id
    assert_response :gone

    # this won't work since the way never existed
    delete :delete, :id => 0
    assert_response :not_found
  end

end
