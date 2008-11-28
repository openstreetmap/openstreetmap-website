require File.dirname(__FILE__) + '/../test_helper'
require 'way_controller'

class WayControllerTest < ActionController::TestCase
  api_fixtures

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
  end

  ##
  # check the "full" mode
  def test_full
    Way.find(:all).each do |way|
      get :full, :id => way.id

      # full call should say "gone" for non-visible ways...
      unless way.visible
        assert_response :gone
        next
      end

      # otherwise it should say success
      assert_response :success
      
      # Check the way is correctly returned
      assert_select "osm way[id=#{way.id}][version=#{way.version}][visible=#{way.visible}]", 1
      
      # check that each node in the way appears once in the output as a 
      # reference and as the node element. note the slightly dodgy assumption
      # that nodes appear only once. this is currently the case with the
      # fixtures, but it doesn't have to be.
      way.nodes.each do |n|
        assert_select "osm way nd[ref=#{n.id}]", 1
        assert_select "osm node[id=#{n.id}][version=#{n.version}][lat=#{n.lat}][lon=#{n.lon}]", 1
      end
    end
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
  def test_invalid_duplicate_tags
    # setup auth
    basic_authorization(users(:normal_user).email, "test")

    # add the tag into the existing xml
    way_str = "<osm><way changeset='1'>"
    way_str << "<tag k='addr:housenumber' v='1'/>"
    way_str << "<tag k='addr:housenumber' v='2'/>"
    way_str << "</way></osm>";

    # try and upload it
    content way_str
    put :create
    assert_response :bad_request, 
    "adding new duplicate tags to a way should fail with 'bad request'"
  end

  ##
  # test that a call to ways_for_node returns all ways that contain the node
  # and none that don't.
  def test_ways_for_node
    # in current fixtures ways 1 and 3 all use node 3. ways 2 and 4 
    # *used* to use it but doesn't.
    get :ways_for_node, :id => current_nodes(:used_node_1).id
    assert_response :success
    ways_xml = XML::Parser.string(@response.body).parse
    assert_not_nil ways_xml, "failed to parse ways_for_node response"

    # check that the set of IDs match expectations
    expected_way_ids = [ current_ways(:visible_way).id,
                         current_ways(:used_way).id
                       ]
    found_way_ids = ways_xml.find("//osm/way").collect { |w| w["id"].to_i }
    assert_equal expected_way_ids, found_way_ids,
      "expected ways for node #{current_nodes(:used_node_1).id} did not match found"
    
    # check the full ways to ensure we're not missing anything
    expected_way_ids.each do |id|
      way_xml = ways_xml.find("//osm/way[@id=#{id}]").first
      assert_ways_are_equal(Way.find(id),
                            Way.from_xml_node(way_xml))
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
