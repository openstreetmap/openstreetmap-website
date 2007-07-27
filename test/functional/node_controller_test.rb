require File.dirname(__FILE__) + '/../test_helper'
require 'node_controller'

# Re-raise errors caught by the controller.
class NodeController; def rescue_action(e) raise e end; end

class NodeControllerTest < Test::Unit::TestCase
  api_fixtures

  def setup
    @controller = NodeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_create
    # cannot read password from fixture as it is stored as MD5 digest
    basic_authorization("test@openstreetmap.org", "test");  
    # create a node with random lat/lon
    lat = rand(100)-50 + rand
    lon = rand(100)-50 + rand
    content("<osm><node lat='#{lat}' lon='#{lon}' /></osm>")
    put :create
    # hope for success
    assert_response :success, "node upload did not return success status"
    # read id of created node and search for it
    nodeid = @response.body
    checknode = Node.find(nodeid)
    assert_not_nil checknode, "uploaded node not found in data base after upload"
    # compare values
    assert_in_delta lat, checknode.latitude, 1E-8, "saved node does not match requested latitude"
    assert_in_delta lon, checknode.longitude, 1E-8, "saved node does not match requested longitude"
    assert_equal users(:normal_user).id, checknode.user_id, "saved node does not belong to user that created it"
    assert_equal true, checknode.visible, "saved node is not visible"
  end

  def test_read
    # check that a visible node is returned properly
    get :read, :id => current_nodes(:visible_node).id
    assert_response :success

    # check that an invisible node is not returned
    get :read, :id => current_nodes(:invisible_node).id
    assert_response :gone

    # check chat a non-existent node is not returned
    get :read, :id => 0
    assert_response :not_found
  end

  # this tests deletion restrictions - basic deletion is tested in the unit
  # tests for node!
  def test_delete

    # first try to delete node without auth
    delete :delete, :id => current_nodes(:visible_node).id
    assert_response :unauthorized

    # now set auth
    basic_authorization("test@openstreetmap.org", "test");  

    # this should work
    delete :delete, :id => current_nodes(:visible_node).id
    assert_response :success

    # this won't work since the node is already deleted
    delete :delete, :id => current_nodes(:invisible_node).id
    assert_response :gone

    # this won't work since the node never existed
    delete :delete, :id => 0
    assert_response :not_found

    # this won't work since the node is in use
    delete :delete, :id => current_nodes(:used_node_1).id
    assert_response :precondition_failed
  end


  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c
  end
end
