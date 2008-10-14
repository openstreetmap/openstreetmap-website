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
    basic_authorization(users(:normal_user).email, "test");
    
    # create a node with random lat/lon
    lat = rand(100)-50 + rand
    lon = rand(100)-50 + rand
    # normal user has a changeset open, so we'll use that.
    changeset = changesets(:normal_user_first_change)
    # create a minimal xml file
    content("<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'/></osm>")
    put :create
    # hope for success
    assert_response :success, "node upload did not return success status"

    # read id of created node and search for it
    nodeid = @response.body
    checknode = Node.find(nodeid)
    assert_not_nil checknode, "uploaded node not found in data base after upload"
    # compare values
    assert_in_delta lat * 10000000, checknode.latitude, 1, "saved node does not match requested latitude"
    assert_in_delta lon * 10000000, checknode.longitude, 1, "saved node does not match requested longitude"
    assert_equal changesets(:normal_user_first_change).id, checknode.changeset_id, "saved node does not belong to changeset that it was created in"
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
    basic_authorization(users(:normal_user).email, "test");  

    # try to delete with an invalid (closed) changeset
    content update_changeset(current_nodes(:visible_node).to_xml,
                             changesets(:normal_user_closed_change).id)
    delete :delete, :id => current_nodes(:visible_node).id
    assert_response :conflict

    # try to delete with an invalid (non-existent) changeset
    content update_changeset(current_nodes(:visible_node).to_xml,0)
    delete :delete, :id => current_nodes(:visible_node).id
    assert_response :conflict

    # valid delete now takes a payload
    content(nodes(:visible_node).to_xml)
    delete :delete, :id => current_nodes(:visible_node).id
    assert_response :success

    # valid delete should return the new version number, which should
    # be greater than the old version number
    assert @response.body.to_i > current_nodes(:visible_node).version,
       "delete request should return a new version number for node"

    # this won't work since the node is already deleted
    content(nodes(:invisible_node).to_xml)
    delete :delete, :id => current_nodes(:invisible_node).id
    assert_response :gone

    # this won't work since the node never existed
    delete :delete, :id => 0
    assert_response :not_found

    ## these test whether nodes which are in-use can be deleted:
    # in a way...
    content(nodes(:used_node_1).to_xml)
    delete :delete, :id => current_nodes(:used_node_1).id
    assert_response :precondition_failed,
       "shouldn't be able to delete a node used in a way (#{@response.body})"

    # in a relation...
    content(nodes(:node_used_by_relationship).to_xml)
    delete :delete, :id => current_nodes(:node_used_by_relationship).id
    assert_response :precondition_failed,
       "shouldn't be able to delete a node used in a relation (#{@response.body})"
  end

  ##
  # tests whether the API works and prevents incorrect use while trying
  # to update nodes.
  def test_update
    # try and update a node without authorisation
    # first try to delete node without auth
    content current_nodes(:visible_node).to_xml
    put :update, :id => current_nodes(:visible_node).id
    assert_response :unauthorized
    
    # setup auth
    basic_authorization(users(:normal_user).email, "test")

    ## trying to break changesets

    # try and update in someone else's changeset
    content update_changeset(current_nodes(:visible_node).to_xml,
                             changesets(:second_user_first_change).id)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, "update with other user's changeset should be rejected"

    # try and update in a closed changeset
    content update_changeset(current_nodes(:visible_node).to_xml,
                             changesets(:normal_user_closed_change).id)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, "update with closed changeset should be rejected"

    # try and update in a non-existant changeset
    content update_changeset(current_nodes(:visible_node).to_xml, 0)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, "update with changeset=0 should be rejected"

    ## try and submit invalid updates
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, 'lat', 91.0);
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lat=91 should be rejected"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, 'lat', -91.0);
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lat=-91 should be rejected"
    
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, 'lon', 181.0);
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lon=181 should be rejected"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, 'lon', -181.0);
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lon=-181 should be rejected"

    ## next, attack the versioning
    current_node_version = current_nodes(:visible_node).version

    # try and submit a version behind
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, 
                             'version', current_node_version - 1);
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, "should have failed on old version number"
    
    # try and submit a version ahead
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, 
                             'version', current_node_version + 1);
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, "should have failed on skipped version number"

    # try and submit total crap in the version field
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, 
                             'version', 'p1r4t3s!');
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, 
       "should not be able to put 'p1r4at3s!' in the version field"
    
    ## finally, produce a good request which should work
    content current_nodes(:visible_node).to_xml
    put :update, :id => current_nodes(:visible_node).id
    assert_response :success, "a valid update request failed"
  end

  ##
  # test adding tags to a node
  def test_duplicate_tags
    # setup auth
    basic_authorization(users(:normal_user).email, "test")

    # add an identical tag to the node
    tag_xml = XML::Node.new("tag")
    tag_xml['k'] = current_node_tags(:t1).k
    tag_xml['v'] = current_node_tags(:t1).v

    # add the tag into the existing xml
    node_xml = current_nodes(:visible_node).to_xml
    node_xml.find("//osm/node").first << tag_xml

    # try and upload it
    content node_xml
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, 
       "adding duplicate tags to a node should fail with 'bad request'"
  end

  # test whether string injection is possible
  def test_string_injection
    basic_authorization(users(:normal_user).email, "test")
    changeset_id = changesets(:normal_user_first_change).id

    # try and put something into a string that the API might 
    # use unquoted and therefore allow code injection...
    content "<osm><node lat='0' lon='0' changeset='#{changeset_id}'>" +
      '<tag k="#{@user.inspect}" v="0"/>' +
      '</node></osm>'
    put :create
    assert_response :success
    nodeid = @response.body

    # find the node in the database
    checknode = Node.find(nodeid)
    assert_not_nil checknode, "node not found in data base after upload"
    
    # and grab it using the api
    get :read, :id => nodeid
    assert_response :success
    apinode = Node.from_xml(@response.body)
    assert_not_nil apinode, "downloaded node is nil, but shouldn't be"
    
    # check the tags are not corrupted
    assert_equal checknode.tags, apinode.tags
    assert apinode.tags.include?('#{@user.inspect}')
  end

  def basic_authorization(user, pass)
    @request.env["HTTP_AUTHORIZATION"] = "Basic %s" % Base64.encode64("#{user}:#{pass}")
  end

  def content(c)
    @request.env["RAW_POST_DATA"] = c.to_s
  end

  ##
  # update the changeset_id of a node element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, 'changeset', changeset_id)
  end

  ##
  # update an attribute in the node element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/node").first[name] = value.to_s
    return xml
  end

  ##
  # parse some xml
  def xml_parse(xml)
    parser = XML::Parser.new
    parser.string = xml
    parser.parse
  end
end
