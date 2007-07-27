require File.dirname(__FILE__) + '/../test_helper'
require 'segment_controller'

# Re-raise errors caught by the controller.
class SegmentController; def rescue_action(e) raise e end; end

class SegmentControllerTest < Test::Unit::TestCase
  api_fixtures

  def setup
    @controller = SegmentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_create
    # cannot read password from fixture as it is stored as MD5 digest
    basic_authorization("test@openstreetmap.org", "test");  
    na = current_nodes(:used_node_1).id
    nb = current_nodes(:used_node_2).id
    content("<osm><segment from='#{na}' to='#{nb}' /></osm>")
    put :create
    # hope for success
    assert_response :success, "segment upload did not return success status"
    # read id of created segment and search for it
    segmentid = @response.body
    checksegment = Segment.find(segmentid)
    assert_not_nil checksegment, "uploaded segment not found in data base after upload"
    # compare values
    assert_equal na, checksegment.node_a, "saved segment does not match requested from-node"
    assert_equal nb, checksegment.node_b, "saved segment does not match requested to-node"
    assert_equal users(:normal_user).id, checksegment.user_id, "saved segment does not belong to user that created it"
    assert_equal true, checksegment.visible, "saved segment is not visible"
  end

  def test_create_invalid
    basic_authorization("test@openstreetmap.org", "test");  
    # create a segment with one invalid node
    na = current_nodes(:used_node_1).id
    nb = 0
    content("<osm><segment from='#{na}' to='#{nb}' /></osm>")
    put :create
    # expect failure
    assert_response :precondition_failed, "upload of invalid segment did not return 'precondition failed'"
  end

  def test_read
    # check that a visible segment is returned properly
    get :read, :id => current_segments(:visible_segment).id
    assert_response :success
    # TODO: check for <segment> tag in return data

    # check that an invisible segment is not returned
    get :read, :id => current_segments(:invisible_segment).id
    assert_response :gone

    # check chat a non-existent segment is not returned
    get :read, :id => 0
    assert_response :not_found
  end

  # this tests deletion restrictions - basic deletion is tested in the unit
  # tests for segment!
  def test_delete

    # first try to delete segment without auth
    delete :delete, :id => current_segments(:visible_segment).id
    assert_response :unauthorized

    # now set auth
    basic_authorization("test@openstreetmap.org", "test");  

    # this should work
    delete :delete, :id => current_segments(:visible_segment).id
    assert_response :success

    # this won't work since the segment is already deleted
    delete :delete, :id => current_segments(:invisible_segment).id
    assert_response :gone

    # this won't work since the segment never existed
    delete :delete, :id => 0
    assert_response :not_found

    # this won't work since the segment is in use
    delete :delete, :id => current_segments(:used_segment).id
    assert_response :precondition_failed
  end


  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c
  end
end
