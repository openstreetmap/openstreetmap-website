require File.dirname(__FILE__) + '/../test_helper'
require 'way_controller'

# Re-raise errors caught by the controller.
class WayController; def rescue_action(e) raise e end; end

class WayControllerTest < Test::Unit::TestCase
  api_fixtures

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

    # check the "ways for node" mode
    get :ways_for_node, :id => current_nodes(:used_node_1).id
    assert_response :success
    # FIXME check whether this contains the stuff we want!
    print @response.body

    # check the "full" mode
    get :full, :id => current_ways(:visible_way).id
    assert_response :success
    # FIXME check whether this contains the stuff we want!
    print @response.body
  end

  # -------------------------------------
  # Test simple way creation.
  # -------------------------------------

  def test_create
    nid1 = current_nodes(:used_node_1).id
    nid2 = current_nodes(:used_node_2).id
    basic_authorization "test@openstreetmap.org", "test"

    # create a way with pre-existing nodes
    content "<osm><way><nd ref='#{nid1}'/><nd ref='#{nid2}'/><tag k='test' v='yes' /></way></osm>"
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
    assert_equal checkway.nds.length, 2, 
        "saved way does not contain exactly one node"
    assert_equal checkway.nds[0], nid1, 
        "saved way does not contain the right node on pos 0"
    assert_equal checkway.nds[1], nid2, 
        "saved way does not contain the right node on pos 1"
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

    # create a way with non-existing node
    content "<osm><way><nd ref='0'/><tag k='test' v='yes' /></way></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "way upload with invalid node did not return 'precondition failed'"

    # create a way with no nodes
    content "<osm><way><tag k='test' v='yes' /></way></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "way upload with no node did not return 'precondition failed'"
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
