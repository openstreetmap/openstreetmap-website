require "test_helper"

module Api
  class NodesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/nodes", :method => :get },
        { :controller => "api/nodes", :action => "index" }
      )
      assert_routing(
        { :path => "/api/0.6/nodes.json", :method => :get },
        { :controller => "api/nodes", :action => "index", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/nodes", :method => :post },
        { :controller => "api/nodes", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1", :method => :get },
        { :controller => "api/nodes", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1.json", :method => :get },
        { :controller => "api/nodes", :action => "show", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1", :method => :put },
        { :controller => "api/nodes", :action => "update", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1", :method => :delete },
        { :controller => "api/nodes", :action => "destroy", :id => "1" }
      )

      assert_recognizes(
        { :controller => "api/nodes", :action => "create" },
        { :path => "/api/0.6/node/create", :method => :put }
      )
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
      get api_nodes_path
      assert_response :bad_request

      # check error when no parameter value provided
      get api_nodes_path(:nodes => "")
      assert_response :bad_request

      # test a working call
      get api_nodes_path(:nodes => "#{node1.id},#{node2.id},#{node3.id},#{node4.id},#{node5.id}")
      assert_response :success
      assert_select "osm" do
        assert_select "node", :count => 5
        assert_select "node[id='#{node1.id}'][visible='true']", :count => 1
        assert_select "node[id='#{node2.id}'][visible='false']", :count => 1
        assert_select "node[id='#{node3.id}'][visible='true']", :count => 1
        assert_select "node[id='#{node4.id}'][visible='true']", :count => 1
        assert_select "node[id='#{node5.id}'][visible='false']", :count => 1
      end

      # test a working call with json format
      get api_nodes_path(:nodes => "#{node1.id},#{node2.id},#{node3.id},#{node4.id},#{node5.id}", :format => "json")

      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 5, js["elements"].count
      assert_equal 5, (js["elements"].count { |a| a["type"] == "node" })
      assert_equal 1, (js["elements"].count { |a| a["id"] == node1.id && a["visible"].nil? })
      assert_equal 1, (js["elements"].count { |a| a["id"] == node2.id && a["visible"] == false })
      assert_equal 1, (js["elements"].count { |a| a["id"] == node3.id && a["visible"].nil? })
      assert_equal 1, (js["elements"].count { |a| a["id"] == node4.id && a["visible"].nil? })
      assert_equal 1, (js["elements"].count { |a| a["id"] == node5.id && a["visible"] == false })

      # check error when a non-existent node is included
      get api_nodes_path(:nodes => "#{node1.id},#{node2.id},#{node3.id},#{node4.id},#{node5.id},0")
      assert_response :not_found
    end

    def test_create_when_unauthorized
      changeset = create(:changeset)
      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"

      assert_no_difference "OldNode.count" do
        post api_nodes_path, :params => xml

        assert_response :unauthorized
      end

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_create_by_private_user
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :user => user)

      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"
      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_require_public_data "node create did not return forbidden status"
      end

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_create
      user = create(:user)
      changeset = create(:changeset, :user => user)
      lat = rand(-50..50) + rand
      lon = rand(-50..50) + rand
      xml = "<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'/></osm>"

      assert_difference "Node.count", 1 do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :success, "node upload did not return success status"
      end

      created_node_id = @response.body
      node = Node.find(created_node_id)
      assert_in_delta lat * 10000000, node.latitude, 1, "saved node does not match requested latitude"
      assert_in_delta lon * 10000000, node.longitude, 1, "saved node does not match requested longitude"
      assert_equal changeset.id, node.changeset_id, "saved node does not belong to changeset that it was created in"
      assert node.visible, "saved node is not visible"
    end

    def test_create_invalid_osm_structure
      user = create(:user)
      xml = "<create/>"

      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :bad_request, "node upload did not return bad_request status"
      end
      assert_equal "Cannot parse valid node from xml string <create/>. XML doesn't contain an osm/node element.", @response.body
    end

    def test_create_without_lat
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = "<osm><node lon='3.23' changeset='#{changeset.id}'/></osm>"

      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :bad_request, "node upload did not return bad_request status"
      end
      assert_equal "Cannot parse valid node from xml string <node lon=\"3.23\" changeset=\"#{changeset.id}\"/>. lat missing", @response.body

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_create_without_lon
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = "<osm><node lat='3.434' changeset='#{changeset.id}'/></osm>"

      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :bad_request, "node upload did not return bad_request status"
      end
      assert_equal "Cannot parse valid node from xml string <node lat=\"3.434\" changeset=\"#{changeset.id}\"/>. lon missing", @response.body

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_create_with_non_numeric_lat
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = "<osm><node lat='abc' lon='3.23' changeset='#{changeset.id}'/></osm>"

      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :bad_request, "node upload did not return bad_request status"
      end
      assert_equal "Cannot parse valid node from xml string <node lat=\"abc\" lon=\"3.23\" changeset=\"#{changeset.id}\"/>. lat not a number", @response.body

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_create_with_non_numeric_lon
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = "<osm><node lat='3.434' lon='abc' changeset='#{changeset.id}'/></osm>"

      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :bad_request, "node upload did not return bad_request status"
      end
      assert_equal "Cannot parse valid node from xml string <node lat=\"3.434\" lon=\"abc\" changeset=\"#{changeset.id}\"/>. lon not a number", @response.body

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_create_with_tag_too_long
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = "<osm><node lat='3.434' lon='3.23' changeset='#{changeset.id}'><tag k='foo' v='#{'x' * 256}'/></node></osm>"

      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :bad_request, "node upload did not return bad_request status"
      end
      assert_match(/ v: is too long \(maximum is 255 characters\) /, @response.body)

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    ##
    # try and put something into a string that the API might
    # use unquoted and therefore allow code injection
    def test_create_with_string_injection_by_private_user
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :user => user)
      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'>" \
            "<tag k='\#{@user.inspect}' v='0'/>" \
            "</node></osm>"

      assert_no_difference "Node.count" do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_require_public_data "Shouldn't be able to create with non-public user"
      end

      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    ##
    # try and put something into a string that the API might
    # use unquoted and therefore allow code injection
    def test_create_with_string_injection
      user = create(:user)
      changeset = create(:changeset, :user => user)

      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'>" \
            "<tag k='\#{@user.inspect}' v='0'/>" \
            "</node></osm>"

      assert_difference "Node.count", 1 do
        post api_nodes_path, :params => xml, :headers => bearer_authorization_header(user)

        assert_response :success
      end

      created_node_id = @response.body
      db_node = Node.find(created_node_id)

      get api_node_path(created_node_id)

      assert_response :success

      api_node = Node.from_xml(@response.body)
      assert_not_nil api_node, "downloaded node is nil, but shouldn't be"
      assert_equal db_node.tags, api_node.tags, "tags are corrupted"
      assert_includes api_node.tags, "\#{@user.inspect}"
    end

    def test_show_not_found
      get api_node_path(0)
      assert_response :not_found
    end

    def test_show_deleted
      get api_node_path(create(:node, :deleted))
      assert_response :gone
    end

    def test_show
      node = create(:node, :timestamp => "2021-02-03T00:00:00Z")

      get api_node_path(node)

      assert_response :success
      assert_not_nil @response.header["Last-Modified"]
      assert_equal "2021-02-03T00:00:00Z", Time.parse(@response.header["Last-Modified"]).utc.xmlschema
    end

    def test_show_lat_lon_decimal_format
      node = create(:node, :latitude => (0.00004 * OldNode::SCALE).to_i, :longitude => (0.00008 * OldNode::SCALE).to_i)

      get api_node_path(node)
      assert_match(/lat="0.0000400"/, response.body)
      assert_match(/lon="0.0000800"/, response.body)
    end

    def test_destroy_when_unauthorized
      node = create(:node)

      delete api_node_path(node)

      assert_response :unauthorized

      node.reload
      assert_predicate node, :visible?
    end

    def test_destroy_in_closed_changeset_by_private_user
      node = create(:node)
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :closed, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)
      assert_require_public_data "non-public user shouldn't be able to delete node"

      node.reload
      assert_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_in_missing_changeset_by_private_user
      node = create(:node)
      user = create(:user, :data_public => false)
      xml = update_changeset xml_for_node(node), 0

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)
      assert_require_public_data "shouldn't be able to delete node, when user's data is private"

      node.reload
      assert_predicate node, :visible?
    end

    def test_destroy_by_private_user
      user = create(:user, :data_public => false)
      node = create(:node)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)
      assert_require_public_data "shouldn't be able to delete node when user's data isn't public'"

      node.reload
      assert_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_deleted_node_by_private_user
      node = create(:node, :deleted)
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_require_public_data

      node.reload
      assert_not_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_missing_node_by_private_user
      user = create(:user, :data_public => false)

      delete api_node_path(0), :headers => bearer_authorization_header(user)

      assert_require_public_data
    end

    def test_destroy_node_in_way_by_private_user
      node = create(:node)
      create(:way_node, :node => node)
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_require_public_data "shouldn't be able to delete a node used in a way (#{@response.body})"

      node.reload
      assert_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_node_in_relation_by_private_user
      node = create(:node)
      create(:relation_member, :member => node)
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_require_public_data "shouldn't be able to delete a node used in a relation (#{@response.body})"

      node.reload
      assert_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_in_closed_changeset
      node = create(:node)
      user = create(:user)
      changeset = create(:changeset, :closed, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict

      node.reload
      assert_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_in_missing_changeset
      node = create(:node)
      user = create(:user)
      xml = update_changeset xml_for_node(node), 0

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict

      node.reload
      assert_predicate node, :visible?
    end

    def test_destroy_different_node
      node = create(:node)
      other_node = create(:node)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(other_node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :bad_request, "should not be able to delete a node with a different ID from the XML"

      node.reload
      assert_predicate node, :visible?
      other_node.reload
      assert_predicate other_node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_invalid_osm_structure
      node = create(:node)
      user = create(:user)
      xml = "<delete/>"

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :bad_request, "should not be able to delete a node without a valid XML payload"

      node.reload
      assert_predicate node, :visible?
    end

    def test_destroy
      node = create(:node)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :success

      response_node_version = @response.body.to_i
      assert_operator response_node_version, :>, node.version, "delete request should return a new version number for node"
      node.reload
      assert_not_predicate node, :visible?
      assert_equal response_node_version, node.version
    end

    def test_destroy_twice
      user = create(:user)
      node = create(:node, :changeset => create(:changeset, :user => user))
      xml = xml_for_node(node)

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :success

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :gone
    end

    def test_destroy_missing_node
      user = create(:user)

      delete api_node_path(0), :headers => bearer_authorization_header(user)

      assert_response :not_found
    end

    def test_destroy_node_in_ways
      node = create(:node)
      way_node = create(:way_node, :node => node)
      way_node2 = create(:way_node, :node => node)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :precondition_failed, "shouldn't be able to delete a node used in a way (#{@response.body})"
      assert_equal "Precondition failed: Node #{node.id} is still used by ways #{way_node.way.id},#{way_node2.way.id}.", @response.body

      node.reload
      assert_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_destroy_node_in_relations
      node = create(:node)
      relation_member = create(:relation_member, :member => node)
      relation_member2 = create(:relation_member, :member => node)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      delete api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :precondition_failed, "shouldn't be able to delete a node used in a relation (#{@response.body})"
      assert_equal "Precondition failed: Node #{node.id} is still used by relations #{relation_member.relation.id},#{relation_member2.relation.id}.", @response.body

      node.reload
      assert_predicate node, :visible?
      changeset.reload
      assert_equal 0, changeset.num_changes
      assert_predicate changeset, :num_type_changes_in_sync?
    end

    def test_update_when_unauthorized
      node = create(:node)
      xml = xml_for_node(node)

      put api_node_path(node), :params => xml.to_s

      assert_response :unauthorized
    end

    def test_update_in_changeset_of_other_user_by_private_user
      node = create(:node)
      user = create(:user, :data_public => false)
      changeset = create(:changeset)
      xml = update_changeset xml_for_node(node), changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_require_public_data "update with other user's changeset should be forbidden when data isn't public"
    end

    def test_update_in_closed_changeset_by_private_user
      node = create(:node)
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :closed, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_require_public_data "update with closed changeset should be forbidden, when data isn't public"
    end

    def test_update_in_missing_changeset_by_private_user
      node = create(:node)
      user = create(:user, :data_public => false)
      xml = update_changeset xml_for_node(node), 0

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_require_public_data "update with changeset=0 should be forbidden, when data isn't public"
    end

    def test_update_with_invalid_attr_values_by_private_user
      node = create(:node)
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :user => user)
      invalid_attr_values = [["lat", 91.0], ["lat", -91.0], ["lon", 181.0], ["lon", -181.0]]

      invalid_attr_values.each do |name, value|
        xml = xml_attr_rewrite xml_for_node(node), name, value
        xml = update_changeset xml, changeset.id

        put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

        assert_require_public_data "node at #{name}=#{value} should be forbidden, when data isn't public"
      end
    end

    def test_update_by_private_user
      node = create(:node)
      user = create(:user, :data_public => false)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_require_public_data "should have failed with a forbidden when data isn't public"
    end

    def test_update_in_changeset_of_other_user
      node = create(:node)
      user = create(:user)
      changeset = create(:changeset)
      xml = update_changeset xml_for_node(node), changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict, "update with other user's changeset should be rejected"
    end

    def test_update_in_closed_changeset
      node = create(:node)
      user = create(:user)
      changeset = create(:changeset, :closed, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict, "update with closed changeset should be rejected"
    end

    def test_update_in_missing_changeset
      user = create(:user)
      node = create(:node)
      xml = update_changeset xml_for_node(node), 0

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict, "update with changeset=0 should be rejected"
    end

    def test_update_with_invalid_attr_values
      user = create(:user)
      node = create(:node)
      changeset = create(:changeset, :user => user)
      invalid_attr_values = [["lat", 91.0], ["lat", -91.0], ["lon", 181.0], ["lon", -181.0]]

      invalid_attr_values.each do |name, value|
        xml = xml_attr_rewrite xml_for_node(node), name, value
        xml = update_changeset xml, changeset.id

        put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

        assert_response :bad_request, "node at #{name}=#{value} should be rejected"
      end
    end

    def test_update_with_version_behind
      node = create(:node, :version => 2)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = xml_attr_rewrite xml_for_node(node), "version", node.version - 1
      xml = update_changeset xml, changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict, "should have failed on old version number"
    end

    def test_update_with_version_ahead
      node = create(:node, :version => 2)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = xml_attr_rewrite xml_for_node(node), "version", node.version + 1
      xml = update_changeset xml, changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict, "should have failed on skipped version number"
    end

    def test_update_with_invalid_version
      node = create(:node)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = xml_attr_rewrite xml_for_node(node), "version", "p1r4t3s!"
      xml = update_changeset xml, changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :conflict, "should not be able to put 'p1r4at3s!' in the version field"
    end

    def test_update_other_node
      node = create(:node)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(create(:node)), changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :bad_request, "should not be able to update a node with a different ID from the XML"
    end

    def test_update_invalid_osm_structure
      node = create(:node)
      user = create(:user)
      xml = "<update/>"

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :bad_request, "should not be able to update a node with non-OSM XML doc."
    end

    def test_update
      node = create(:node)
      user = create(:user)
      changeset = create(:changeset, :user => user)
      xml = update_changeset xml_for_node(node), changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :success, "a valid update request failed"
    end

    def test_update_with_duplicate_tags
      node = create(:node)
      create(:node_tag, :node => node, :k => "test_key", :v => "test_value")
      user = create(:user)
      changeset = create(:changeset, :user => user)

      duplicate_tag_xml = XML::Node.new("tag")
      duplicate_tag_xml["k"] = "test_key"
      duplicate_tag_xml["v"] = "test_value"

      xml = xml_for_node(node)
      xml.find("//osm/node").first << duplicate_tag_xml
      xml = update_changeset xml, changeset.id

      put api_node_path(node), :params => xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :bad_request, "adding duplicate tags to a node should fail with 'bad request'"
      assert_equal "Element node/#{node.id} has duplicate tags with key test_key", @response.body
    end

    ##
    # test initial rate limit
    def test_initial_rate_limit
      # create a user
      user = create(:user)

      # create a changeset that puts us near the initial rate limit
      changeset = create(:changeset, :user => user,
                                     :created_at => Time.now.utc - 5.minutes,
                                     :num_changes => Settings.initial_changes_per_hour - 1)

      # create authentication header
      auth_header = bearer_authorization_header user

      # try creating a node
      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"
      post api_nodes_path, :params => xml, :headers => auth_header
      assert_response :success, "node create did not return success status"

      # get the id of the node we created
      nodeid = @response.body

      # try updating the node, which should be rate limited
      xml = "<osm><node id='#{nodeid}' version='1' lat='1' lon='1' changeset='#{changeset.id}'/></osm>"
      put api_node_path(nodeid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "node update did not hit rate limit"

      # try deleting the node, which should be rate limited
      xml = "<osm><node id='#{nodeid}' version='2' lat='1' lon='1' changeset='#{changeset.id}'/></osm>"
      delete api_node_path(nodeid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "node delete did not hit rate limit"

      # try creating a node, which should be rate limited
      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"
      post api_nodes_path, :params => xml, :headers => auth_header
      assert_response :too_many_requests, "node create did not hit rate limit"
    end

    ##
    # test maximum rate limit
    def test_maximum_rate_limit
      # create a user
      user = create(:user)

      # create a changeset to establish our initial edit time
      changeset = create(:changeset, :user => user,
                                     :created_at => Time.now.utc - 28.days)

      # create changeset to put us near the maximum rate limit
      total_changes = Settings.max_changes_per_hour - 1
      while total_changes.positive?
        changes = [total_changes, Changeset::MAX_ELEMENTS].min
        changeset = create(:changeset, :user => user,
                                       :created_at => Time.now.utc - 5.minutes,
                                       :num_changes => changes)
        total_changes -= changes
      end

      # create authentication header
      auth_header = bearer_authorization_header user

      # try creating a node
      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"
      post api_nodes_path, :params => xml, :headers => auth_header
      assert_response :success, "node create did not return success status"

      # get the id of the node we created
      nodeid = @response.body

      # try updating the node, which should be rate limited
      xml = "<osm><node id='#{nodeid}' version='1' lat='1' lon='1' changeset='#{changeset.id}'/></osm>"
      put api_node_path(nodeid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "node update did not hit rate limit"

      # try deleting the node, which should be rate limited
      xml = "<osm><node id='#{nodeid}' version='2' lat='1' lon='1' changeset='#{changeset.id}'/></osm>"
      delete api_node_path(nodeid), :params => xml, :headers => auth_header
      assert_response :too_many_requests, "node delete did not hit rate limit"

      # try creating a node, which should be rate limited
      xml = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"
      post api_nodes_path, :params => xml, :headers => auth_header
      assert_response :too_many_requests, "node create did not hit rate limit"
    end

    private

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
  end
end
