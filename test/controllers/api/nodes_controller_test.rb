require "test_helper"
require_relative "elements_test_helper"

module Api
  class NodesControllerTest < ActionDispatch::IntegrationTest
    include ElementsTestHelper

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

    def test_index_no_param
      get api_nodes_path

      assert_response :bad_request
      assert_match "parameter nodes is required", @response.body
    end

    def test_index_empty_param
      get api_nodes_path(:nodes => "")

      assert_response :bad_request
      assert_match "No nodes were given", @response.body
    end

    def test_index
      node1 = create(:node)
      node2 = create(:node, :deleted)
      node3 = create(:node)
      node4 = create(:node, :with_history, :version => 2)
      node5 = create(:node, :deleted, :with_history, :version => 2)

      get api_nodes_path(:nodes => "#{node1.id},#{node2.id},#{node3.id},#{node4.id},#{node5.id}")

      assert_response :success
      assert_dom "osm" do
        assert_dom "node", :count => 5
        assert_dom "node[id='#{node1.id}'][visible='true']", :count => 1
        assert_dom "node[id='#{node2.id}'][visible='false']", :count => 1
        assert_dom "node[id='#{node3.id}'][visible='true']", :count => 1
        assert_dom "node[id='#{node4.id}'][visible='true']", :count => 1
        assert_dom "node[id='#{node5.id}'][visible='false']", :count => 1
      end
    end

    def test_index_json
      node1 = create(:node)
      node2 = create(:node, :deleted)
      node3 = create(:node)
      node4 = create(:node, :with_history, :version => 2)
      node5 = create(:node, :deleted, :with_history, :version => 2)

      get api_nodes_path(:nodes => "#{node1.id},#{node2.id},#{node3.id},#{node4.id},#{node5.id}", :format => "json")

      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal 5, js["elements"].count
      assert_equal(5, js["elements"].count { |a| a["type"] == "node" })
      assert_equal(1, js["elements"].count { |a| a["id"] == node1.id && a["visible"].nil? })
      assert_equal(1, js["elements"].count { |a| a["id"] == node2.id && a["visible"] == false })
      assert_equal(1, js["elements"].count { |a| a["id"] == node3.id && a["visible"].nil? })
      assert_equal(1, js["elements"].count { |a| a["id"] == node4.id && a["visible"].nil? })
      assert_equal(1, js["elements"].count { |a| a["id"] == node5.id && a["visible"] == false })
    end

    def test_index_nonexisting_element
      get api_nodes_path(:nodes => "0")

      assert_response :not_found
    end

    def test_index_existing_and_nonexisting_element
      node = create(:node)

      get api_nodes_path(:nodes => "#{node.id},0")

      assert_response :not_found
    end

    def test_index_versions
      node = create(:node, :with_history, :version => 2)
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 1), :k => "name", :v => "old")
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 2), :k => "name", :v => "new")
      create(:node_tag, :node => node, :k => "name", :v => "new")

      get api_nodes_path(:nodes => "#{node.id}v1,#{node.id}v2")

      assert_response :success
      assert_dom "osm" do
        assert_dom "node", :count => 2
        assert_dom "node[id='#{node.id}'][version='1']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "old"
          end
        end
        assert_dom "node[id='#{node.id}'][version='2']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "new"
          end
        end
      end
    end

    def test_index_nonversion_and_versions
      node1 = create(:node, :with_history)
      node2 = create(:node, :with_history, :version => 2)
      create(:old_node_tag, :old_node => node1.old_nodes.find_by(:version => 1), :k => "name", :v => "one")
      create(:node_tag, :node => node1, :k => "name", :v => "one")
      create(:old_node_tag, :old_node => node2.old_nodes.find_by(:version => 1), :k => "name", :v => "old")
      create(:old_node_tag, :old_node => node2.old_nodes.find_by(:version => 2), :k => "name", :v => "new")
      create(:node_tag, :node => node2, :k => "name", :v => "new")

      get api_nodes_path(:nodes => "#{node1.id},#{node2.id}v1,#{node2.id}v2")

      assert_response :success
      assert_dom "osm" do
        assert_dom "node", :count => 3
        assert_dom "node[id='#{node1.id}'][version='1']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "one"
          end
        end
        assert_dom "node[id='#{node2.id}'][version='1']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "old"
          end
        end
        assert_dom "node[id='#{node2.id}'][version='2']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "new"
          end
        end
      end
    end

    def test_index_nonexistent_version
      node = create(:node, :with_history, :version => 2)

      get api_nodes_path(:nodes => "#{node.id}v3")

      assert_response :not_found
    end

    def test_index_existing_and_nonexisting_version
      node = create(:node, :with_history, :version => 2)

      get api_nodes_path(:nodes => "#{node.id}v2,#{node.id}v3")

      assert_response :not_found
    end

    def test_index_when_specified_version_coincides_with_top_version
      node = create(:node, :with_history, :version => 2)

      get api_nodes_path(:nodes => "#{node.id},#{node.id}v1,#{node.id}v2")

      assert_response :success
      assert_dom "osm" do
        assert_dom "node", :count => 2
        assert_dom "node[id='#{node.id}'][version='1']", :count => 1
        assert_dom "node[id='#{node.id}'][version='2']", :count => 1
      end
    end

    def test_index_redacted_version
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_nodes_path(:nodes => "#{node.id}v1")

      assert_response :not_found
    end

    def test_index_redacted_and_visible_version
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_nodes_path(:nodes => "#{node.id}v1,#{node.id}v2")

      assert_response :not_found
    end

    def test_index_visible_version_of_element_with_redacted_version
      node = create(:node, :with_history, :version => 2)
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 1), :k => "name", :v => "secret")
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 2), :k => "name", :v => "public")
      create(:node_tag, :node => node, :k => "name", :v => "public")
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_nodes_path(:nodes => "#{node.id}v2")

      assert_response :success
      assert_dom "osm" do
        assert_dom "node", :count => 1
        assert_dom "node[id='#{node.id}'][version='2']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "public"
          end
        end
      end
    end

    def test_index_redacted_version_with_show_redactions_when_unauthorized
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_nodes_path(:nodes => "#{node.id}v1", :show_redactions => "true")

      assert_response :not_found
    end

    def test_index_redacted_version_with_show_redactions_for_regular_user
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header

      get api_nodes_path(:nodes => "#{node.id}v1", :show_redactions => "true"), :headers => auth_header

      assert_response :not_found
    end

    def test_index_redacted_version_with_show_redactions_for_moderator
      node = create(:node, :with_history, :version => 2)
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 1), :k => "name", :v => "secret")
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 2), :k => "name", :v => "public")
      create(:node_tag, :node => node, :k => "name", :v => "public")
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_nodes_path(:nodes => "#{node.id}v1", :show_redactions => "true"), :headers => auth_header

      assert_response :success
      assert_dom "osm" do
        assert_dom "node", :count => 1
        assert_dom "node[id='#{node.id}'][version='1']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "secret"
          end
        end
      end
    end

    def test_index_redacted_and_visible_version_with_show_redactions_for_moderator
      node = create(:node, :with_history, :version => 2)
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 1), :k => "name", :v => "secret")
      create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 2), :k => "name", :v => "public")
      create(:node_tag, :node => node, :k => "name", :v => "public")
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_nodes_path(:nodes => "#{node.id}v1,#{node.id}v2", :show_redactions => "true"), :headers => auth_header

      assert_response :success
      assert_dom "osm" do
        assert_dom "node", :count => 2
        assert_dom "node[id='#{node.id}'][version='1']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "secret"
          end
        end
        assert_dom "node[id='#{node.id}'][version='2']", :count => 1 do
          assert_dom "tag", :count => 1
          assert_dom "tag[k='name']", :count => 1 do
            assert_dom "> @v", "public"
          end
        end
      end
    end

    def test_create_when_unauthorized
      with_unchanging_request do |_headers, changeset|
        osm = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"

        post api_nodes_path, :params => osm

        assert_response :unauthorized
      end
    end

    def test_create_by_private_user
      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = "<osm><node lat='0' lon='0' changeset='#{changeset.id}'/></osm>"

        post api_nodes_path, :params => osm, :headers => headers

        assert_require_public_data "node create did not return forbidden status"
      end
    end

    def test_create
      with_request do |headers, changeset|
        lat = rand(-50..50) + rand
        lon = rand(-50..50) + rand

        assert_difference "Node.count", 1 do
          osm = "<osm><node lat='#{lat}' lon='#{lon}' changeset='#{changeset.id}'/></osm>"

          post api_nodes_path, :params => osm, :headers => headers

          assert_response :success, "node upload did not return success status"
        end

        created_node_id = @response.body
        node = Node.find(created_node_id)
        assert_in_delta lat * 10000000, node.latitude, 1, "saved node does not match requested latitude"
        assert_in_delta lon * 10000000, node.longitude, 1, "saved node does not match requested longitude"
        assert_equal changeset.id, node.changeset_id, "saved node does not belong to changeset that it was created in"
        assert node.visible, "saved node is not visible"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_created_nodes
      end
    end

    def test_create_with_invalid_osm_structure
      with_unchanging_request do |headers|
        osm = "<create/>"

        post api_nodes_path, :params => osm, :headers => headers

        assert_response :bad_request, "node upload did not return bad_request status"
        assert_equal "Cannot parse valid node from xml string <create/>. XML doesn't contain an osm/node element.", @response.body
      end
    end

    def test_create_without_lat
      with_unchanging_request do |headers, changeset|
        osm = "<osm><node lon='3.23' changeset='#{changeset.id}'/></osm>"

        post api_nodes_path, :params => osm, :headers => headers

        assert_response :bad_request, "node upload did not return bad_request status"
        assert_equal "Cannot parse valid node from xml string <node lon=\"3.23\" changeset=\"#{changeset.id}\"/>. lat missing", @response.body
      end
    end

    def test_create_without_lon
      with_unchanging_request do |headers, changeset|
        osm = "<osm><node lat='3.434' changeset='#{changeset.id}'/></osm>"

        post api_nodes_path, :params => osm, :headers => headers

        assert_response :bad_request, "node upload did not return bad_request status"
        assert_equal "Cannot parse valid node from xml string <node lat=\"3.434\" changeset=\"#{changeset.id}\"/>. lon missing", @response.body
      end
    end

    def test_create_with_non_numeric_lat
      with_unchanging_request do |headers, changeset|
        osm = "<osm><node lat='abc' lon='3.23' changeset='#{changeset.id}'/></osm>"

        post api_nodes_path, :params => osm, :headers => headers

        assert_response :bad_request, "node upload did not return bad_request status"
        assert_equal "Cannot parse valid node from xml string <node lat=\"abc\" lon=\"3.23\" changeset=\"#{changeset.id}\"/>. lat not a number", @response.body
      end
    end

    def test_create_with_non_numeric_lon
      with_unchanging_request do |headers, changeset|
        osm = "<osm><node lat='3.434' lon='abc' changeset='#{changeset.id}'/></osm>"

        post api_nodes_path, :params => osm, :headers => headers

        assert_response :bad_request, "node upload did not return bad_request status"
        assert_equal "Cannot parse valid node from xml string <node lat=\"3.434\" lon=\"abc\" changeset=\"#{changeset.id}\"/>. lon not a number", @response.body
      end
    end

    def test_create_with_tag_too_long
      with_unchanging_request do |headers, changeset|
        osm = "<osm><node lat='3.434' lon='3.23' changeset='#{changeset.id}'><tag k='foo' v='#{'x' * 256}'/></node></osm>"

        post api_nodes_path, :params => osm, :headers => headers

        assert_response :bad_request, "node upload did not return bad_request status"
        assert_match(/ v: is too long \(maximum is 255 characters\) /, @response.body)
      end
    end

    ##
    # try and put something into a string that the API might
    # use unquoted and therefore allow code injection
    def test_create_with_string_injection_by_private_user
      with_unchanging_request([:data_public => false]) do |headers, changeset|
        osm = <<~OSM
          <osm>
            <node lat='0' lon='0' changeset='#{changeset.id}'>
              <tag k='\#{@user.inspect}' v='0'/>
            </node>
          </osm>
        OSM

        post api_nodes_path, :params => osm, :headers => headers

        assert_require_public_data "Shouldn't be able to create with non-public user"
      end
    end

    ##
    # try and put something into a string that the API might
    # use unquoted and therefore allow code injection
    def test_create_with_string_injection
      with_request do |headers, changeset|
        assert_difference "Node.count", 1 do
          osm = <<~OSM
            <osm>
              <node lat='0' lon='0' changeset='#{changeset.id}'>
                <tag k='\#{@user.inspect}' v='0'/>
              </node>
            </osm>
          OSM

          post api_nodes_path, :params => osm, :headers => headers

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
      with_unchanging(:node) do |node|
        delete api_node_path(node)

        assert_response :unauthorized
      end
    end

    def test_destroy_in_closed_changeset_by_private_user
      with_unchanging(:node) do |node|
        with_unchanging_request([:data_public => false], [:closed]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "non-public user shouldn't be able to delete node"
        end
      end
    end

    def test_destroy_in_missing_changeset_by_private_user
      with_unchanging(:node) do |node|
        with_unchanging_request([:data_public => false]) do |headers|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, 0

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "shouldn't be able to delete node, when user's data is private"
        end
      end
    end

    def test_destroy_by_private_user
      with_unchanging(:node) do |node|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "shouldn't be able to delete node when user's data isn't public'"
        end
      end
    end

    def test_destroy_deleted_node_by_private_user
      with_unchanging(:node, :deleted) do |node|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = "<osm><node id='#{node.id}' changeset='#{changeset.id}' version='1' lat='0' lon='0'/></osm>"

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data
        end
      end
    end

    def test_destroy_missing_node_by_private_user
      with_unchanging_request([:data_public => false]) do |headers|
        delete api_node_path(0), :headers => headers

        assert_require_public_data
      end
    end

    def test_destroy_node_in_way_by_private_user
      with_unchanging(:node) do |node|
        create(:way_node, :node => node)

        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "shouldn't be able to delete a node used in a way (#{@response.body})"
        end
      end
    end

    def test_destroy_node_in_relation_by_private_user
      with_unchanging(:node) do |node|
        create(:relation_member, :member => node)

        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "shouldn't be able to delete a node used in a relation (#{@response.body})"
        end
      end
    end

    def test_destroy_in_closed_changeset
      with_unchanging(:node) do |node|
        with_unchanging_request([], [:closed]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict
        end
      end
    end

    def test_destroy_in_missing_changeset
      with_unchanging(:node) do |node|
        with_unchanging_request do |headers|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, 0

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict
        end
      end
    end

    def test_destroy_different_node
      with_unchanging(:node) do |node|
        with_unchanging(:node) do |other_node|
          with_unchanging_request do |headers, changeset|
            osm_xml = xml_for_node other_node
            osm_xml = update_changeset osm_xml, changeset.id

            delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

            assert_response :bad_request, "should not be able to delete a node with a different ID from the XML"
          end
        end
      end
    end

    def test_destroy_invalid_osm_structure
      with_unchanging(:node) do |node|
        with_unchanging_request do |headers|
          osm = "<delete/>"

          delete api_node_path(node), :params => osm, :headers => headers

          assert_response :bad_request, "should not be able to delete a node without a valid XML payload"
        end
      end
    end

    def test_destroy
      with_request do |headers, changeset|
        node = create(:node)
        osm_xml = xml_for_node node
        osm_xml = update_changeset osm_xml, changeset.id

        delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

        assert_response :success

        response_node_version = @response.body.to_i
        assert_operator response_node_version, :>, node.version, "delete request should return a new version number for node"
        node.reload
        assert_not_predicate node, :visible?
        assert_equal response_node_version, node.version

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_deleted_nodes
      end
    end

    def test_destroy_twice
      user = create(:user)
      node = create(:node, :changeset => create(:changeset, :user => user))
      osm_xml = xml_for_node node

      delete api_node_path(node), :params => osm_xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :success

      delete api_node_path(node), :params => osm_xml.to_s, :headers => bearer_authorization_header(user)

      assert_response :gone
    end

    def test_destroy_deleted_node
      with_unchanging(:node, :deleted) do |node|
        with_unchanging_request do |headers, changeset|
          osm = "<osm><node id='#{node.id}' changeset='#{changeset.id}' version='1' lat='0' lon='0'/></osm>"

          delete api_node_path(node), :params => osm, :headers => headers

          assert_response :gone
        end
      end
    end

    def test_destroy_missing_node
      with_unchanging_request do |headers|
        delete api_node_path(0), :headers => headers

        assert_response :not_found
      end
    end

    def test_destroy_node_in_ways
      with_unchanging(:node) do |node|
        way_node = create(:way_node, :node => node)
        way_node2 = create(:way_node, :node => node)

        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :precondition_failed, "shouldn't be able to delete a node used in a way (#{@response.body})"
          assert_equal "Precondition failed: Node #{node.id} is still used by ways #{way_node.way.id},#{way_node2.way.id}.", @response.body
        end
      end
    end

    def test_destroy_node_in_relations
      with_unchanging(:node) do |node|
        relation_member = create(:relation_member, :member => node)
        relation_member2 = create(:relation_member, :member => node)

        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          delete api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :precondition_failed, "shouldn't be able to delete a node used in a relation (#{@response.body})"
          assert_equal "Precondition failed: Node #{node.id} is still used by relations #{relation_member.relation.id},#{relation_member2.relation.id}.", @response.body
        end
      end
    end

    def test_update_when_unauthorized
      with_unchanging(:node) do |node|
        osm_xml = xml_for_node node

        put api_node_path(node), :params => osm_xml.to_s

        assert_response :unauthorized
      end
    end

    def test_update_in_changeset_of_other_user_by_private_user
      with_unchanging(:node) do |node|
        other_user = create(:user)

        with_unchanging_request([:data_public => false], [:user => other_user]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "update with other user's changeset should be forbidden when data isn't public"
        end
      end
    end

    def test_update_in_closed_changeset_by_private_user
      with_unchanging(:node) do |node|
        with_unchanging_request([:data_public => false], [:closed]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "update with closed changeset should be forbidden, when data isn't public"
        end
      end
    end

    def test_update_in_missing_changeset_by_private_user
      with_unchanging(:node) do |node|
        with_unchanging_request([:data_public => false]) do |headers|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, 0

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "update with changeset=0 should be forbidden, when data isn't public"
        end
      end
    end

    def test_update_with_lat_too_large_by_private_user
      check_update_with_invalid_attr_value "lat", 91.0, :data_public => false
    end

    def test_update_with_lat_too_small_by_private_user
      check_update_with_invalid_attr_value "lat", -91.0, :data_public => false
    end

    def test_update_with_lon_too_large_by_private_user
      check_update_with_invalid_attr_value "lon", 181.0, :data_public => false
    end

    def test_update_with_lon_too_small_by_private_user
      check_update_with_invalid_attr_value "lon", -181.0, :data_public => false
    end

    def test_update_by_private_user
      with_unchanging(:node) do |node|
        with_unchanging_request([:data_public => false]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_require_public_data "should have failed with a forbidden when data isn't public"
        end
      end
    end

    def test_update_in_changeset_of_other_user
      with_unchanging(:node) do |node|
        other_user = create(:user)

        with_unchanging_request([], [:user => other_user]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "update with other user's changeset should be rejected"
        end
      end
    end

    def test_update_in_closed_changeset
      with_unchanging(:node) do |node|
        with_unchanging_request([], [:closed]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "update with closed changeset should be rejected"
        end
      end
    end

    def test_update_in_missing_changeset
      with_unchanging(:node) do |node|
        with_unchanging_request do |headers|
          osm_xml = xml_for_node node
          osm_xml = update_changeset osm_xml, 0

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "update with changeset=0 should be rejected"
        end
      end
    end

    def test_update_with_lat_too_large
      check_update_with_invalid_attr_value "lat", 91.0
    end

    def test_update_with_lat_too_small
      check_update_with_invalid_attr_value "lat", -91.0
    end

    def test_update_with_lon_too_large
      check_update_with_invalid_attr_value "lon", 181.0
    end

    def test_update_with_lon_too_small
      check_update_with_invalid_attr_value "lon", -181.0
    end

    def test_update_with_version_behind
      with_unchanging(:node, :version => 2) do |node|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = xml_attr_rewrite osm_xml, "version", node.version - 1
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "should have failed on old version number"
        end
      end
    end

    def test_update_with_version_ahead
      with_unchanging(:node, :version => 2) do |node|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = xml_attr_rewrite osm_xml, "version", node.version + 1
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "should have failed on skipped version number"
        end
      end
    end

    def test_update_with_invalid_version
      with_unchanging(:node) do |node|
        with_unchanging_request do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = xml_attr_rewrite osm_xml, "version", "p1r4t3s!"
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :conflict, "should not be able to put 'p1r4at3s!' in the version field"
        end
      end
    end

    def test_update_other_node
      with_unchanging(:node) do |node|
        with_unchanging(:node) do |other_node|
          with_unchanging_request do |headers, changeset|
            osm_xml = xml_for_node other_node
            osm_xml = update_changeset osm_xml, changeset.id

            put api_node_path(node), :params => osm_xml.to_s, :headers => headers

            assert_response :bad_request, "should not be able to update a node with a different ID from the XML"
          end
        end
      end
    end

    def test_update_with_invalid_osm_structure
      with_unchanging(:node) do |node|
        with_unchanging_request do |headers|
          osm = "<update/>"

          put api_node_path(node), :params => osm, :headers => headers

          assert_response :bad_request, "should not be able to update a node with non-OSM XML doc."
        end
      end
    end

    def test_update
      with_request do |headers, changeset|
        node = create(:node)
        osm_xml = xml_for_node node
        osm_xml = update_changeset osm_xml, changeset.id

        put api_node_path(node), :params => osm_xml.to_s, :headers => headers

        assert_response :success, "a valid update request failed"

        changeset.reload
        assert_equal 1, changeset.num_changes
        assert_predicate changeset, :num_type_changes_in_sync?
        assert_equal 1, changeset.num_modified_nodes
      end
    end

    def test_update_with_duplicate_tags
      with_unchanging(:node) do |node|
        create(:node_tag, :node => node, :k => "key_to_duplicate", :v => "value_to_duplicate")

        with_unchanging_request do |headers, changeset|
          tag_xml = XML::Node.new("tag")
          tag_xml["k"] = "key_to_duplicate"
          tag_xml["v"] = "value_to_duplicate"

          osm_xml = xml_for_node node
          osm_xml.find("//osm/node").first << tag_xml
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          assert_response :bad_request, "adding duplicate tags to a node should fail with 'bad request'"
          assert_equal "Element node/#{node.id} has duplicate tags with key key_to_duplicate", @response.body
        end
      end
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

    def check_update_with_invalid_attr_value(name, value, data_public: true)
      with_unchanging(:node) do |node|
        with_unchanging_request([:data_public => data_public]) do |headers, changeset|
          osm_xml = xml_for_node node
          osm_xml = xml_attr_rewrite osm_xml, name, value
          osm_xml = update_changeset osm_xml, changeset.id

          put api_node_path(node), :params => osm_xml.to_s, :headers => headers

          if data_public
            assert_response :bad_request, "node at #{name}=#{value} should be rejected"
          else
            assert_require_public_data "node at #{name}=#{value} should be forbidden, when data isn't public"
          end
        end
      end
    end

    def affected_models
      [Node, NodeTag,
       OldNode, OldNodeTag]
    end

    ##
    # update an attribute in the node element
    def xml_attr_rewrite(xml, name, value)
      xml.find("//osm/node").first[name] = value.to_s
      xml
    end
  end
end
