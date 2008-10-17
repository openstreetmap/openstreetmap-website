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
    @request.env["RAW_POST_DATA"] = c.to_s
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
    #print @response.body
    # Needs to be updated when changing fixtures
    # The generator should probably be defined in the environment.rb file
    # in the same place as the api version
    assert_select "osm[version=#{API_VERSION}][generator=\"OpenStreetMap server\"]", 1
    assert_select "osm way", 3
    assert_select "osm way nd", 3
    assert_select "osm way tag", 3

    # check the "full" mode
    get :full, :id => current_ways(:visible_way).id
    assert_response :success
    # FIXME check whether this contains the stuff we want!
    #print @response.body
    # Check the way is correctly returned
    way = current_ways(:visible_way)
    assert_select "osm way[id=#{way.id}][version=#{way.version}][visible=#{way.visible}]", 1
    assert_select "osm way nd[ref=#{way.way_nodes[0].node_id}]", 1
    # Check that the node is correctly returned
    nd = current_ways(:visible_way).nodes
    assert_equal 1, nd.count
    nda = nd[0]
    assert_select "osm node[id=#{nda.id}][version=#{nda.version}][lat=#{nda.lat}][lon=#{nda.lon}]", 1 
  end

  # -------------------------------------
  # Test simple way creation.
  # -------------------------------------

  def test_create
    nid1 = current_nodes(:used_node_1).id
    nid2 = current_nodes(:used_node_2).id
    basic_authorization "test@openstreetmap.org", "test"

    # use the first user's open changeset
    changeset_id = changesets(:normal_user_first_change).id
    
    # create a way with pre-existing nodes
    content "<osm><way changeset='#{changeset_id}'>" +
      "<nd ref='#{nid1}'/><nd ref='#{nid2}'/>" + 
      "<tag k='test' v='yes' /></way></osm>"
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
    assert_equal checkway.changeset_id, changeset_id,
        "saved way does not belong to the correct changeset"
    assert_equal users(:normal_user).id, checkway.changeset.user_id, 
        "saved way does not belong to user that created it"
    assert_equal true, checkway.visible, 
        "saved way is not visible"
  end

  # -------------------------------------
  # Test creating some invalid ways.
  # -------------------------------------

  def test_create_invalid
    basic_authorization "test@openstreetmap.org", "test"

    # use the first user's open changeset
    open_changeset_id = changesets(:normal_user_first_change).id
    closed_changeset_id = changesets(:normal_user_closed_change).id
    nid1 = current_nodes(:used_node_1).id

    # create a way with non-existing node
    content "<osm><way changeset='#{open_changeset_id}'>" + 
      "<nd ref='0'/><tag k='test' v='yes' /></way></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "way upload with invalid node did not return 'precondition failed'"

    # create a way with no nodes
    content "<osm><way changeset='#{open_changeset_id}'>" +
      "<tag k='test' v='yes' /></way></osm>"
    put :create
    # expect failure
    assert_response :precondition_failed, 
        "way upload with no node did not return 'precondition failed'"

    # create a way inside a closed changeset
    content "<osm><way changeset='#{closed_changeset_id}'>" +
      "<nd ref='#{nid1}'/></way></osm>"
    put :create
    # expect failure
    assert_response :conflict, 
        "way upload to closed changeset did not return 'conflict'"    
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

    # this shouldn't work as with the 0.6 api we need pay load to delete
    delete :delete, :id => current_ways(:visible_way).id
    assert_response :bad_request
    
    # Now try without having a changeset
    content "<osm><way id='#{current_ways(:visible_way).id}'></osm>"
    delete :delete, :id => current_ways(:visible_way).id
    assert_response :bad_request
    
    # try to delete with an invalid (closed) changeset
    content update_changeset(current_ways(:visible_way).to_xml,
                             changesets(:normal_user_closed_change).id)
    delete :delete, :id => current_ways(:visible_way).id
    assert_response :conflict

    # try to delete with an invalid (non-existent) changeset
    content update_changeset(current_ways(:visible_way).to_xml,0)
    delete :delete, :id => current_ways(:visible_way).id
    assert_response :conflict

    # Now try with a valid changeset
    content current_ways(:visible_way).to_xml
    delete :delete, :id => current_ways(:visible_way).id
    assert_response :success

    # check the returned value - should be the new version number
    # valid delete should return the new version number, which should
    # be greater than the old version number
    assert @response.body.to_i > current_ways(:visible_way).version,
       "delete request should return a new version number for way"

    # this won't work since the way is already deleted
    content current_ways(:invisible_way).to_xml
    delete :delete, :id => current_ways(:invisible_way).id
    assert_response :gone

    # this shouldn't work as the way is used in a relation
    content current_ways(:used_way).to_xml
    delete :delete, :id => current_ways(:used_way).id
    assert_response :precondition_failed, 
       "shouldn't be able to delete a way used in a relation (#{@response.body})"

    # this won't work since the way never existed
    delete :delete, :id => 0
    assert_response :not_found
  end

  # ------------------------------------------------------------
  # test tags handling
  # ------------------------------------------------------------

  ##
  # Try adding a duplicate of an existing tag to a way
  def test_add_duplicate_tags
    # setup auth
    basic_authorization(users(:normal_user).email, "test")

    # add an identical tag to the way
    tag_xml = XML::Node.new("tag")
    tag_xml['k'] = current_way_tags(:t1).k
    tag_xml['v'] = current_way_tags(:t1).v

    # add the tag into the existing xml
    way_xml = current_ways(:visible_way).to_xml
    way_xml.find("//osm/way").first << tag_xml

    # try and upload it
    content way_xml
    put :update, :id => current_ways(:visible_way).id
    assert_response :bad_request, 
       "adding a duplicate tag to a way should fail with 'bad request'"
  end

  ##
  # Try adding a new duplicate tags to a way
  def test_new_duplicate_tags
    # setup auth
    basic_authorization(users(:normal_user).email, "test")

    # create duplicate tag
    tag_xml = XML::Node.new("tag")
    tag_xml['k'] = "i_am_a_duplicate"
    tag_xml['v'] = "foobar"

    # add the tag into the existing xml
    way_xml = current_ways(:visible_way).to_xml

    # add two copies of the tag
    way_xml.find("//osm/way").first << tag_xml.copy(true) << tag_xml

    # try and upload it
    content way_xml
    put :update, :id => current_ways(:visible_way).id
    assert_response :bad_request, 
       "adding new duplicate tags to a way should fail with 'bad request'"
  end

  ##
  # Try adding a new duplicate tags to a way.
  # But be a bit subtle - use unicode decoding ambiguities to use different
  # binary strings which have the same decoding.
  #
  # NOTE: I'm not sure this test is working correctly, as a lot of the tag
  # keys seem to come out as "addr��housenumber". It might be something to
  # do with Ruby's unicode handling...?
  def test_invalid_duplicate_tags
    # setup auth
    basic_authorization(users(:normal_user).email, "test")

    # add the tag into the existing xml
    way_str = "<osm><way changeset='1'>"
    way_str << "<tag k='addr:housenumber' v='1'/>"

    # all of these keys have the same unicode decoding, but are binary
    # not equal. libxml should make these identical as it decodes the
    # XML document...
    [ "addr\xc0\xbahousenumber",
      "addr\xe0\x80\xbahousenumber",
      "addr\xf0\x80\x80\xbahousenumber" ].each do |key|
      # copy the XML doc to add the tags
      way_str_copy = way_str.clone

      # add all new tags to the way
      way_str_copy << "<tag k='" << key << "' v='1'/>"
      way_str_copy << "</way></osm>";

      # try and upload it
      content way_str_copy
      put :create
      assert_response :bad_request, 
         "adding new duplicate tags to a way should fail with 'bad request'"
    end
  end

  ##
  # update the changeset_id of a node element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, 'changeset', changeset_id)
  end

  ##
  # update an attribute in the node element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/way").first[name] = value.to_s
    return xml
  end
end
