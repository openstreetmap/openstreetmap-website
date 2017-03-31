require "test_helper"

class NodeControllerTest < ActionController::TestCase
  api_fixtures

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/node/create", :method => :put },
      { :controller => "node", :action => "create" }
    )
    assert_routing(
      { :path => "/api/0.6/node/1", :method => :get },
      { :controller => "node", :action => "read", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/node/1", :method => :put },
      { :controller => "node", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/node/1", :method => :delete },
      { :controller => "node", :action => "delete", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/nodes", :method => :get },
      { :controller => "node", :action => "nodes" }
    )
  end

  def test_create
    # cannot read password from fixture as it is stored as MD5 digest
    ## First try with no auth

    # create a node with random lat/lon
    lat = rand(100) - 50 + rand
    lon = rand(100) - 50 + rand
    # normal user has a changeset open, so we'll use that.
    changeset = changesets(:normal_user_first_change)
    # create a minimal xml file
    content("<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'/></osm>")
    assert_difference("OldNode.count", 0) do
      put :create
    end
    # hope for unauthorized
    assert_response :unauthorized, "node upload did not return unauthorized status"

    ## Now try with the user which doesn't have their data public
    basic_authorization(users(:normal_user).email, "test")

    # create a node with random lat/lon
    lat = rand(100) - 50 + rand
    lon = rand(100) - 50 + rand
    # normal user has a changeset open, so we'll use that.
    changeset = changesets(:normal_user_first_change)
    # create a minimal xml file
    content("<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'/></osm>")
    assert_difference("Node.count", 0) do
      put :create
    end
    # hope for success
    assert_require_public_data "node create did not return forbidden status"

    ## Now try with the user that has the public data
    basic_authorization(users(:public_user).email, "test")

    # create a node with random lat/lon
    lat = rand(100) - 50 + rand
    lon = rand(100) - 50 + rand
    # normal user has a changeset open, so we'll use that.
    changeset = changesets(:public_user_first_change)
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
    assert_equal changesets(:public_user_first_change).id, checknode.changeset_id, "saved node does not belong to changeset that it was created in"
    assert_equal true, checknode.visible, "saved node is not visible"
  end

  def test_create_invalid_xml
    ## Only test public user here, as test_create should cover what's the forbiddens
    ## that would occur here
    # Initial setup
    basic_authorization(users(:public_user).email, "test")
    # normal user has a changeset open, so we'll use that.
    changeset = changesets(:public_user_first_change)
    lat = 3.434
    lon = 3.23

    # test that the upload is rejected when xml is valid, but osm doc isn't
    content("<create/>")
    put :create
    assert_response :bad_request, "node upload did not return bad_request status"
    assert_equal "Cannot parse valid node from xml string <create/>. XML doesn't contain an osm/node element.", @response.body

    # test that the upload is rejected when no lat is supplied
    # create a minimal xml file
    content("<osm><node lon='#{lon}' changeset='#{changeset.id}'/></osm>")
    put :create
    # hope for success
    assert_response :bad_request, "node upload did not return bad_request status"
    assert_equal "Cannot parse valid node from xml string <node lon=\"3.23\" changeset=\"#{changeset.id}\"/>. lat missing", @response.body

    # test that the upload is rejected when no lon is supplied
    # create a minimal xml file
    content("<osm><node lat='#{lat}' changeset='#{changeset.id}'/></osm>")
    put :create
    # hope for success
    assert_response :bad_request, "node upload did not return bad_request status"
    assert_equal "Cannot parse valid node from xml string <node lat=\"3.434\" changeset=\"#{changeset.id}\"/>. lon missing", @response.body

    # test that the upload is rejected when lat is non-numeric
    # create a minimal xml file
    content("<osm><node lat='abc' lon='#{lon}' changeset='#{changeset.id}'/></osm>")
    put :create
    # hope for success
    assert_response :bad_request, "node upload did not return bad_request status"
    assert_equal "Cannot parse valid node from xml string <node lat=\"abc\" lon=\"#{lon}\" changeset=\"#{changeset.id}\"/>. lat not a number", @response.body

    # test that the upload is rejected when lon is non-numeric
    # create a minimal xml file
    content("<osm><node lat='#{lat}' lon='abc' changeset='#{changeset.id}'/></osm>")
    put :create
    # hope for success
    assert_response :bad_request, "node upload did not return bad_request status"
    assert_equal "Cannot parse valid node from xml string <node lat=\"#{lat}\" lon=\"abc\" changeset=\"#{changeset.id}\"/>. lon not a number", @response.body

    # test that the upload is rejected when we have a tag which is too long
    content("<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'><tag k='foo' v='#{'x' * 256}'/></node></osm>")
    put :create
    assert_response :bad_request, "node upload did not return bad_request status"
    assert_equal ["NodeTag ", " v: is too long (maximum is 255 characters) (\"#{'x' * 256}\")"], @response.body.split(/[0-9]+,foo:/)
  end

  def test_read
    # check that a visible node is returned properly
    get :read, :id => create(:node).id
    assert_response :success

    # check that an deleted node is not returned
    get :read, :id => create(:node, :deleted).id
    assert_response :gone

    # check chat a non-existent node is not returned
    get :read, :id => 0
    assert_response :not_found
  end

  # this tests deletion restrictions - basic deletion is tested in the unit
  # tests for node!
  def test_delete
    private_user = create(:user, :data_public => false)
    private_user_changeset = create(:changeset, :user => private_user)
    private_user_closed_changeset = create(:changeset, :closed, :user => private_user)
    private_node = create(:node, :changeset => private_user_changeset)
    private_deleted_node = create(:node, :deleted, :changeset => private_user_changeset)

    ## first try to delete node without auth
    delete :delete, :id => private_node.id
    assert_response :unauthorized

    ## now set auth for the non-data public user
    basic_authorization(private_user.email, "test")

    # try to delete with an invalid (closed) changeset
    content update_changeset(private_node.to_xml, private_user_closed_changeset.id)
    delete :delete, :id => private_node.id
    assert_require_public_data("non-public user shouldn't be able to delete node")

    # try to delete with an invalid (non-existent) changeset
    content update_changeset(private_node.to_xml, 0)
    delete :delete, :id => private_node.id
    assert_require_public_data("shouldn't be able to delete node, when user's data is private")

    # valid delete now takes a payload
    content(private_node.to_xml)
    delete :delete, :id => private_node.id
    assert_require_public_data("shouldn't be able to delete node when user's data isn't public'")

    # this won't work since the node is already deleted
    content(private_deleted_node.to_xml)
    delete :delete, :id => private_deleted_node.id
    assert_require_public_data

    # this won't work since the node never existed
    delete :delete, :id => 0
    assert_require_public_data

    ## these test whether nodes which are in-use can be deleted:
    # in a way...
    private_used_node = create(:node, :changeset => private_user_changeset)
    create(:way_node, :node => private_used_node)

    content(private_used_node.to_xml)
    delete :delete, :id => private_used_node.id
    assert_require_public_data "shouldn't be able to delete a node used in a way (#{@response.body})"

    # in a relation...
    private_used_node2 = create(:node, :changeset => private_user_changeset)
    create(:relation_member, :member => private_used_node2)

    content(private_used_node2.to_xml)
    delete :delete, :id => private_used_node2.id
    assert_require_public_data "shouldn't be able to delete a node used in a relation (#{@response.body})"

    ## now setup for the public data user
    user = create(:user, :data_public => true)
    changeset = create(:changeset, :user => user)
    closed_changeset = create(:changeset, :closed, :user => user)
    node = create(:node, :changeset => changeset)
    basic_authorization(user.email, "test")

    # try to delete with an invalid (closed) changeset
    content update_changeset(node.to_xml, closed_changeset.id)
    delete :delete, :id => node.id
    assert_response :conflict

    # try to delete with an invalid (non-existent) changeset
    content update_changeset(node.to_xml, 0)
    delete :delete, :id => node.id
    assert_response :conflict

    # try to delete a node with a different ID
    other_node = create(:node)
    content(other_node.to_xml)
    delete :delete, :id => node.id
    assert_response :bad_request,
                    "should not be able to delete a node with a different ID from the XML"

    # try to delete a node rubbish in the payloads
    content("<delete/>")
    delete :delete, :id => node.id
    assert_response :bad_request,
                    "should not be able to delete a node without a valid XML payload"

    # valid delete now takes a payload
    content(node.to_xml)
    delete :delete, :id => node.id
    assert_response :success

    # valid delete should return the new version number, which should
    # be greater than the old version number
    assert @response.body.to_i > node.version,
           "delete request should return a new version number for node"

    # deleting the same node twice doesn't work
    content(node.to_xml)
    delete :delete, :id => node.id
    assert_response :gone

    # this won't work since the node never existed
    delete :delete, :id => 0
    assert_response :not_found

    ## these test whether nodes which are in-use can be deleted:
    # in a way...
    used_node = create(:node, :changeset => create(:changeset, :user => user))
    way_node = create(:way_node, :node => used_node)
    way_node2 = create(:way_node, :node => used_node)

    content(used_node.to_xml)
    delete :delete, :id => used_node.id
    assert_response :precondition_failed,
                    "shouldn't be able to delete a node used in a way (#{@response.body})"
    assert_equal "Precondition failed: Node #{used_node.id} is still used by ways #{way_node.way.id},#{way_node2.way.id}.", @response.body

    # in a relation...
    used_node2 = create(:node, :changeset => create(:changeset, :user => user))
    relation_member = create(:relation_member, :member => used_node2)
    relation_member2 = create(:relation_member, :member => used_node2)

    content(used_node2.to_xml)
    delete :delete, :id => used_node2.id
    assert_response :precondition_failed,
                    "shouldn't be able to delete a node used in a relation (#{@response.body})"
    assert_equal "Precondition failed: Node #{used_node2.id} is still used by relations #{relation_member.relation.id},#{relation_member2.relation.id}.", @response.body
  end

  ##
  # tests whether the API works and prevents incorrect use while trying
  # to update nodes.
  def test_update
    ## First test with no user credentials
    # try and update a node without authorisation
    # first try to delete node without auth
    content current_nodes(:visible_node).to_xml
    put :update, :id => current_nodes(:visible_node).id
    assert_response :unauthorized

    ## Second test with the private user

    # setup auth
    basic_authorization(users(:normal_user).email, "test")

    ## trying to break changesets

    # try and update in someone else's changeset
    content update_changeset(current_nodes(:visible_node).to_xml,
                             changesets(:public_user_first_change).id)
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data "update with other user's changeset should be forbidden when date isn't public"

    # try and update in a closed changeset
    content update_changeset(current_nodes(:visible_node).to_xml,
                             changesets(:normal_user_closed_change).id)
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data "update with closed changeset should be forbidden, when data isn't public"

    # try and update in a non-existant changeset
    content update_changeset(current_nodes(:visible_node).to_xml, 0)
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data("update with changeset=0 should be forbidden, when data isn't public")

    ## try and submit invalid updates
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lat", 91.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data "node at lat=91 should be forbidden, when data isn't public"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lat", -91.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data "node at lat=-91 should be forbidden, when data isn't public"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lon", 181.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data "node at lon=181 should be forbidden, when data isn't public"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lon", -181.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data "node at lon=-181 should be forbidden, when data isn't public"

    ## finally, produce a good request which should work
    content current_nodes(:visible_node).to_xml
    put :update, :id => current_nodes(:visible_node).id
    assert_require_public_data "should have failed with a forbidden when data isn't public"

    ## Finally test with the public user

    # try and update a node without authorisation
    # first try to delete node without auth
    content current_nodes(:visible_node).to_xml
    put :update, :id => current_nodes(:visible_node).id
    assert_response :forbidden

    # setup auth
    basic_authorization(users(:public_user).email, "test")

    ## trying to break changesets

    # try and update in someone else's changeset
    content update_changeset(current_nodes(:visible_node).to_xml,
                             changesets(:normal_user_first_change).id)
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
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lat", 91.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lat=91 should be rejected"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lat", -91.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lat=-91 should be rejected"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lon", 181.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lon=181 should be rejected"

    content xml_attr_rewrite(current_nodes(:visible_node).to_xml, "lon", -181.0)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request, "node at lon=-181 should be rejected"

    ## next, attack the versioning
    current_node_version = current_nodes(:visible_node).version

    # try and submit a version behind
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml,
                             "version", current_node_version - 1)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, "should have failed on old version number"

    # try and submit a version ahead
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml,
                             "version", current_node_version + 1)
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict, "should have failed on skipped version number"

    # try and submit total crap in the version field
    content xml_attr_rewrite(current_nodes(:visible_node).to_xml,
                             "version", "p1r4t3s!")
    put :update, :id => current_nodes(:visible_node).id
    assert_response :conflict,
                    "should not be able to put 'p1r4at3s!' in the version field"

    ## try an update with the wrong ID
    content current_nodes(:public_visible_node).to_xml
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request,
                    "should not be able to update a node with a different ID from the XML"

    ## try an update with a minimal valid XML doc which isn't a well-formed OSM doc.
    content "<update/>"
    put :update, :id => current_nodes(:visible_node).id
    assert_response :bad_request,
                    "should not be able to update a node with non-OSM XML doc."

    ## finally, produce a good request which should work
    content current_nodes(:public_visible_node).to_xml
    put :update, :id => current_nodes(:public_visible_node).id
    assert_response :success, "a valid update request failed"
  end

  ##
  # test fetching multiple nodes
  def test_nodes
    # check error when no parameter provided
    get :nodes
    assert_response :bad_request

    # check error when no parameter value provided
    get :nodes, :nodes => ""
    assert_response :bad_request

    # test a working call
    get :nodes, :nodes => "1,2,4,15,17"
    assert_response :success
    assert_select "osm" do
      assert_select "node", :count => 5
      assert_select "node[id='1'][visible='true']", :count => 1
      assert_select "node[id='2'][visible='false']", :count => 1
      assert_select "node[id='4'][visible='true']", :count => 1
      assert_select "node[id='15'][visible='true']", :count => 1
      assert_select "node[id='17'][visible='false']", :count => 1
    end

    # check error when a non-existent node is included
    get :nodes, :nodes => "1,2,4,15,17,400"
    assert_response :not_found
  end

  ##
  # test adding tags to a node
  def test_duplicate_tags
    existing = create(:node_tag, :node => current_nodes(:public_visible_node))
    # setup auth
    basic_authorization(users(:public_user).email, "test")

    # add an identical tag to the node
    tag_xml = XML::Node.new("tag")
    tag_xml["k"] = existing.k
    tag_xml["v"] = existing.v

    # add the tag into the existing xml
    node_xml = current_nodes(:public_visible_node).to_xml
    node_xml.find("//osm/node").first << tag_xml

    # try and upload it
    content node_xml
    put :update, :id => current_nodes(:public_visible_node).id
    assert_response :bad_request,
                    "adding duplicate tags to a node should fail with 'bad request'"
    assert_equal "Element node/#{current_nodes(:public_visible_node).id} has duplicate tags with key #{existing.k}", @response.body
  end

  # test whether string injection is possible
  def test_string_injection
    ## First try with the non-data public user
    basic_authorization(users(:normal_user).email, "test")
    changeset_id = changesets(:normal_user_first_change).id

    # try and put something into a string that the API might
    # use unquoted and therefore allow code injection...
    content "<osm><node lat='0' lon='0' changeset='#{changeset_id}'>" +
            '<tag k="#{@user.inspect}" v="0"/>' +
            "</node></osm>"
    put :create
    assert_require_public_data "Shouldn't be able to create with non-public user"

    ## Then try with the public data user
    basic_authorization(users(:public_user).email, "test")
    changeset_id = changesets(:public_user_first_change).id

    # try and put something into a string that the API might
    # use unquoted and therefore allow code injection...
    content "<osm><node lat='0' lon='0' changeset='#{changeset_id}'>" +
            '<tag k="#{@user.inspect}" v="0"/>' +
            "</node></osm>"
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
    assert apinode.tags.include?("\#{@user.inspect}")
  end

  ##
  # update the changeset_id of a node element
  def update_changeset(xml, changeset_id)
    xml_attr_rewrite(xml, "changeset", changeset_id)
  end

  ##
  # update an attribute in the node element
  def xml_attr_rewrite(xml, name, value)
    xml.find("//osm/node").first[name] = value.to_s
    xml
  end

  ##
  # parse some xml
  def xml_parse(xml)
    parser = XML::Parser.string(xml)
    parser.parse
  end
end
