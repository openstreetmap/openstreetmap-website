require "test_helper"

module Api
  class NodesControllerTest < ActionController::TestCase
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/node/create", :method => :put },
        { :controller => "api/nodes", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1", :method => :get },
        { :controller => "api/nodes", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1", :method => :put },
        { :controller => "api/nodes", :action => "update", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1", :method => :delete },
        { :controller => "api/nodes", :action => "delete", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/nodes", :method => :get },
        { :controller => "api/nodes", :action => "index" }
      )
    end

    def test_create
      private_user = create(:user, :data_public => false)
      private_changeset = create(:changeset, :user => private_user)
      user = create(:user)
      changeset = create(:changeset, :user => user)

      # create a node with random lat/lon
      lat = rand(-50..50) + rand
      lon = rand(-50..50) + rand

      ## First try with no auth
      # create a minimal xml file
      xml = "<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'/></osm>"
      assert_difference("OldNode.count", 0) do
        put :create, :body => xml
      end
      # hope for unauthorized
      assert_response :unauthorized, "node upload did not return unauthorized status"

      ## Now try with the user which doesn't have their data public
      basic_authorization private_user.email, "test"

      # create a minimal xml file
      xml = "<osm><node lat='#{lat}' lon='#{lon}' changeset='#{private_changeset.id}'/></osm>"
      assert_difference("Node.count", 0) do
        put :create, :body => xml
      end
      # hope for success
      assert_require_public_data "node create did not return forbidden status"

      ## Now try with the user that has the public data
      basic_authorization user.email, "test"

      # create a minimal xml file
      xml = "<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'/></osm>"
      put :create, :body => xml
      # hope for success
      assert_response :success, "node upload did not return success status"

      # read id of created node and search for it
      nodeid = @response.body
      checknode = Node.find(nodeid)
      assert_not_nil checknode, "uploaded node not found in data base after upload"
      # compare values
      assert_in_delta lat * 10000000, checknode.latitude, 1, "saved node does not match requested latitude"
      assert_in_delta lon * 10000000, checknode.longitude, 1, "saved node does not match requested longitude"
      assert_equal changeset.id, checknode.changeset_id, "saved node does not belong to changeset that it was created in"
      assert_equal true, checknode.visible, "saved node is not visible"
    end

    def test_create_invalid_xml
      ## Only test public user here, as test_create should cover what's the forbiddens
      ## that would occur here

      user = create(:user)
      changeset = create(:changeset, :user => user)

      basic_authorization user.email, "test"
      lat = 3.434
      lon = 3.23

      # test that the upload is rejected when xml is valid, but osm doc isn't
      xml = "<create/>"
      put :create, :body => xml
      assert_response :bad_request, "node upload did not return bad_request status"
      assert_equal "Cannot parse valid node from xml string <create/>. XML doesn't contain an osm/node element.", @response.body

      # test that the upload is rejected when no lat is supplied
      # create a minimal xml file
      xml = "<osm><node lon='#{lon}' changeset='#{changeset.id}'/></osm>"
      put :create, :body => xml
      # hope for success
      assert_response :bad_request, "node upload did not return bad_request status"
      assert_equal "Cannot parse valid node from xml string <node lon=\"3.23\" changeset=\"#{changeset.id}\"/>. lat missing", @response.body

      # test that the upload is rejected when no lon is supplied
      # create a minimal xml file
      xml = "<osm><node lat='#{lat}' changeset='#{changeset.id}'/></osm>"
      put :create, :body => xml
      # hope for success
      assert_response :bad_request, "node upload did not return bad_request status"
      assert_equal "Cannot parse valid node from xml string <node lat=\"3.434\" changeset=\"#{changeset.id}\"/>. lon missing", @response.body

      # test that the upload is rejected when lat is non-numeric
      # create a minimal xml file
      xml = "<osm><node lat='abc' lon='#{lon}' changeset='#{changeset.id}'/></osm>"
      put :create, :body => xml
      # hope for success
      assert_response :bad_request, "node upload did not return bad_request status"
      assert_equal "Cannot parse valid node from xml string <node lat=\"abc\" lon=\"#{lon}\" changeset=\"#{changeset.id}\"/>. lat not a number", @response.body

      # test that the upload is rejected when lon is non-numeric
      # create a minimal xml file
      xml = "<osm><node lat='#{lat}' lon='abc' changeset='#{changeset.id}'/></osm>"
      put :create, :body => xml
      # hope for success
      assert_response :bad_request, "node upload did not return bad_request status"
      assert_equal "Cannot parse valid node from xml string <node lat=\"#{lat}\" lon=\"abc\" changeset=\"#{changeset.id}\"/>. lon not a number", @response.body

      # test that the upload is rejected when we have a tag which is too long
      xml = "<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'><tag k='foo' v='#{'x' * 256}'/></node></osm>"
      put :create, :body => xml
      assert_response :bad_request, "node upload did not return bad_request status"
      assert_equal ["NodeTag ", " v: is too long (maximum is 255 characters) (\"#{'x' * 256}\")"], @response.body.split(/[0-9]+,foo:/)
    end

    def test_show
      # check that a visible node is returned properly
      get :show, :params => { :id => create(:node).id }
      assert_response :success

      # check that an deleted node is not returned
      get :show, :params => { :id => create(:node, :deleted).id }
      assert_response :gone

      # check chat a non-existent node is not returned
      get :show, :params => { :id => 0 }
      assert_response :not_found
    end

    # Ensure the lat/lon is formatted as a decimal e.g. not 4.0e-05
    def test_lat_lon_xml_format
      node = create(:node, :latitude => (0.00004 * OldNode::SCALE).to_i, :longitude => (0.00008 * OldNode::SCALE).to_i)

      get :show, :params => { :id => node.id }
      assert_match(/lat="0.0000400"/, response.body)
      assert_match(/lon="0.0000800"/, response.body)
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
      delete :delete, :params => { :id => private_node.id }
      assert_response :unauthorized

      ## now set auth for the non-data public user
      basic_authorization private_user.email, "test"

      # try to delete with an invalid (closed) changeset
      xml = update_changeset(xml_for_node(private_node), private_user_closed_changeset.id)
      delete :delete, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data("non-public user shouldn't be able to delete node")

      # try to delete with an invalid (non-existent) changeset
      xml = update_changeset(xml_for_node(private_node), 0)
      delete :delete, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data("shouldn't be able to delete node, when user's data is private")

      # valid delete now takes a payload
      xml = xml_for_node(private_node)
      delete :delete, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data("shouldn't be able to delete node when user's data isn't public'")

      # this won't work since the node is already deleted
      xml = xml_for_node(private_deleted_node)
      delete :delete, :params => { :id => private_deleted_node.id }, :body => xml.to_s
      assert_require_public_data

      # this won't work since the node never existed
      delete :delete, :params => { :id => 0 }
      assert_require_public_data

      ## these test whether nodes which are in-use can be deleted:
      # in a way...
      private_used_node = create(:node, :changeset => private_user_changeset)
      create(:way_node, :node => private_used_node)

      xml = xml_for_node(private_used_node)
      delete :delete, :params => { :id => private_used_node.id }, :body => xml.to_s
      assert_require_public_data "shouldn't be able to delete a node used in a way (#{@response.body})"

      # in a relation...
      private_used_node2 = create(:node, :changeset => private_user_changeset)
      create(:relation_member, :member => private_used_node2)

      xml = xml_for_node(private_used_node2)
      delete :delete, :params => { :id => private_used_node2.id }, :body => xml.to_s
      assert_require_public_data "shouldn't be able to delete a node used in a relation (#{@response.body})"

      ## now setup for the public data user
      user = create(:user, :data_public => true)
      changeset = create(:changeset, :user => user)
      closed_changeset = create(:changeset, :closed, :user => user)
      node = create(:node, :changeset => changeset)
      basic_authorization user.email, "test"

      # try to delete with an invalid (closed) changeset
      xml = update_changeset(xml_for_node(node), closed_changeset.id)
      delete :delete, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict

      # try to delete with an invalid (non-existent) changeset
      xml = update_changeset(xml_for_node(node), 0)
      delete :delete, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict

      # try to delete a node with a different ID
      other_node = create(:node)
      xml = xml_for_node(other_node)
      delete :delete, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request,
                      "should not be able to delete a node with a different ID from the XML"

      # try to delete a node rubbish in the payloads
      xml = "<delete/>"
      delete :delete, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request,
                      "should not be able to delete a node without a valid XML payload"

      # valid delete now takes a payload
      xml = xml_for_node(node)
      delete :delete, :params => { :id => node.id }, :body => xml.to_s
      assert_response :success

      # valid delete should return the new version number, which should
      # be greater than the old version number
      assert @response.body.to_i > node.version,
             "delete request should return a new version number for node"

      # deleting the same node twice doesn't work
      xml = xml_for_node(node)
      delete :delete, :params => { :id => node.id }, :body => xml.to_s
      assert_response :gone

      # this won't work since the node never existed
      delete :delete, :params => { :id => 0 }
      assert_response :not_found

      ## these test whether nodes which are in-use can be deleted:
      # in a way...
      used_node = create(:node, :changeset => create(:changeset, :user => user))
      way_node = create(:way_node, :node => used_node)
      way_node2 = create(:way_node, :node => used_node)

      xml = xml_for_node(used_node)
      delete :delete, :params => { :id => used_node.id }, :body => xml.to_s
      assert_response :precondition_failed,
                      "shouldn't be able to delete a node used in a way (#{@response.body})"
      assert_equal "Precondition failed: Node #{used_node.id} is still used by ways #{way_node.way.id},#{way_node2.way.id}.", @response.body

      # in a relation...
      used_node2 = create(:node, :changeset => create(:changeset, :user => user))
      relation_member = create(:relation_member, :member => used_node2)
      relation_member2 = create(:relation_member, :member => used_node2)

      xml = xml_for_node(used_node2)
      delete :delete, :params => { :id => used_node2.id }, :body => xml.to_s
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
      private_user = create(:user, :data_public => false)
      private_node = create(:node, :changeset => create(:changeset, :user => private_user))
      user = create(:user)
      node = create(:node, :changeset => create(:changeset, :user => user))

      xml = xml_for_node(node)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :unauthorized

      ## Second test with the private user

      # setup auth
      basic_authorization private_user.email, "test"

      ## trying to break changesets

      # try and update in someone else's changeset
      xml = update_changeset(xml_for_node(private_node),
                             create(:changeset).id)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "update with other user's changeset should be forbidden when data isn't public"

      # try and update in a closed changeset
      xml = update_changeset(xml_for_node(private_node),
                             create(:changeset, :closed, :user => private_user).id)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "update with closed changeset should be forbidden, when data isn't public"

      # try and update in a non-existant changeset
      xml = update_changeset(xml_for_node(private_node), 0)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "update with changeset=0 should be forbidden, when data isn't public"

      ## try and submit invalid updates
      xml = xml_attr_rewrite(xml_for_node(private_node), "lat", 91.0)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "node at lat=91 should be forbidden, when data isn't public"

      xml = xml_attr_rewrite(xml_for_node(private_node), "lat", -91.0)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "node at lat=-91 should be forbidden, when data isn't public"

      xml = xml_attr_rewrite(xml_for_node(private_node), "lon", 181.0)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "node at lon=181 should be forbidden, when data isn't public"

      xml = xml_attr_rewrite(xml_for_node(private_node), "lon", -181.0)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "node at lon=-181 should be forbidden, when data isn't public"

      ## finally, produce a good request which still won't work
      xml = xml_for_node(private_node)
      put :update, :params => { :id => private_node.id }, :body => xml.to_s
      assert_require_public_data "should have failed with a forbidden when data isn't public"

      ## Finally test with the public user

      # try and update a node without authorisation
      # first try to update node without auth
      xml = xml_for_node(node)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :forbidden

      # setup auth
      basic_authorization user.email, "test"

      ## trying to break changesets

      # try and update in someone else's changeset
      xml = update_changeset(xml_for_node(node),
                             create(:changeset).id)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict, "update with other user's changeset should be rejected"

      # try and update in a closed changeset
      xml = update_changeset(xml_for_node(node),
                             create(:changeset, :closed, :user => user).id)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict, "update with closed changeset should be rejected"

      # try and update in a non-existant changeset
      xml = update_changeset(xml_for_node(node), 0)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict, "update with changeset=0 should be rejected"

      ## try and submit invalid updates
      xml = xml_attr_rewrite(xml_for_node(node), "lat", 91.0)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request, "node at lat=91 should be rejected"

      xml = xml_attr_rewrite(xml_for_node(node), "lat", -91.0)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request, "node at lat=-91 should be rejected"

      xml = xml_attr_rewrite(xml_for_node(node), "lon", 181.0)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request, "node at lon=181 should be rejected"

      xml = xml_attr_rewrite(xml_for_node(node), "lon", -181.0)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request, "node at lon=-181 should be rejected"

      ## next, attack the versioning
      current_node_version = node.version

      # try and submit a version behind
      xml = xml_attr_rewrite(xml_for_node(node),
                             "version", current_node_version - 1)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict, "should have failed on old version number"

      # try and submit a version ahead
      xml = xml_attr_rewrite(xml_for_node(node),
                             "version", current_node_version + 1)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict, "should have failed on skipped version number"

      # try and submit total crap in the version field
      xml = xml_attr_rewrite(xml_for_node(node),
                             "version", "p1r4t3s!")
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :conflict,
                      "should not be able to put 'p1r4at3s!' in the version field"

      ## try an update with the wrong ID
      xml = xml_for_node(create(:node))
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request,
                      "should not be able to update a node with a different ID from the XML"

      ## try an update with a minimal valid XML doc which isn't a well-formed OSM doc.
      xml = "<update/>"
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :bad_request,
                      "should not be able to update a node with non-OSM XML doc."

      ## finally, produce a good request which should work
      xml = xml_for_node(node)
      put :update, :params => { :id => node.id }, :body => xml.to_s
      assert_response :success, "a valid update request failed"
    end

    ##
    # test fetching multiple nodes
    def test_index
      node1 = create(:node)
      node2 = create(:node, :deleted)
      node3 = create(:node)
      node4 = create(:node, :with_history, :version => 2)
      node5 = create(:node, :deleted, :with_history, :version => 2)

      # check error when no parameter provided
      get :index
      assert_response :bad_request

      # check error when no parameter value provided
      get :index, :params => { :nodes => "" }
      assert_response :bad_request

      # test a working call
      get :index, :params => { :nodes => "#{node1.id},#{node2.id},#{node3.id},#{node4.id},#{node5.id}" }
      assert_response :success
      assert_select "osm" do
        assert_select "node", :count => 5
        assert_select "node[id='#{node1.id}'][visible='true']", :count => 1
        assert_select "node[id='#{node2.id}'][visible='false']", :count => 1
        assert_select "node[id='#{node3.id}'][visible='true']", :count => 1
        assert_select "node[id='#{node4.id}'][visible='true']", :count => 1
        assert_select "node[id='#{node5.id}'][visible='false']", :count => 1
      end

      # check error when a non-existent node is included
      get :index, :params => { :nodes => "#{node1.id},#{node2.id},#{node3.id},#{node4.id},#{node5.id},0" }
      assert_response :not_found
    end

    ##
    # test adding tags to a node
    def test_duplicate_tags
      existing_tag = create(:node_tag)
      assert_equal true, existing_tag.node.changeset.user.data_public
      # setup auth
      basic_authorization existing_tag.node.changeset.user.email, "test"

      # add an identical tag to the node
      tag_xml = XML::Node.new("tag")
      tag_xml["k"] = existing_tag.k
      tag_xml["v"] = existing_tag.v

      # add the tag into the existing xml
      node_xml = xml_for_node(existing_tag.node)
      node_xml.find("//osm/node").first << tag_xml

      # try and upload it
      put :update, :params => { :id => existing_tag.node.id }, :body => node_xml.to_s
      assert_response :bad_request,
                      "adding duplicate tags to a node should fail with 'bad request'"
      assert_equal "Element node/#{existing_tag.node.id} has duplicate tags with key #{existing_tag.k}", @response.body
    end

    # test whether string injection is possible
    def test_string_injection
      private_user = create(:user, :data_public => false)
      private_changeset = create(:changeset, :user => private_user)
      user = create(:user)
      changeset = create(:changeset, :user => user)

      ## First try with the non-data public user
      basic_authorization private_user.email, "test"

      # try and put something into a string that the API might
      # use unquoted and therefore allow code injection...
      xml = "<osm><node lat='0' lon='0' changeset='#{private_changeset.id}'>" \
            '<tag k="#{@user.inspect}" v="0"/>' \
            "</node></osm>"
      put :create, :body => xml
      assert_require_public_data "Shouldn't be able to create with non-public user"

      ## Then try with the public data user
      basic_authorization user.email, "test"

      # try and put something into a string that the API might
      # use unquoted and therefore allow code injection...
      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'>" \
            '<tag k="#{@user.inspect}" v="0"/>' \
            "</node></osm>"
      put :create, :body => xml
      assert_response :success
      nodeid = @response.body

      # find the node in the database
      checknode = Node.find(nodeid)
      assert_not_nil checknode, "node not found in data base after upload"

      # and grab it using the api
      get :show, :params => { :id => nodeid }
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
end
