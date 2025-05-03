require "test_helper"

module Api
  module Changesets
    class UploadsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/changeset/1/upload", :method => :post },
          { :controller => "api/changesets/uploads", :action => "create", :changeset_id => "1" }
        )
      end

      def test_upload_when_unauthorized
        changeset = create(:changeset)
        node = create(:node, :latitude => 0, :longitude => 0)

        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='1' lat='2' changeset='#{changeset.id}' version='1'/>
            </modify>
          </osmChange>
        CHANGESET

        post api_changeset_upload_path(changeset), :params => diff

        assert_response :unauthorized

        changeset.reload
        assert_equal 0, changeset.num_changes
        node.reload
        assert_equal 1, node.version
        assert_equal 0, node.latitude
        assert_equal 0, node.longitude
      end

      def test_upload_by_private_user
        user = create(:user, :data_public => false)
        changeset = create(:changeset, :user => user)
        node = create(:node, :latitude => 0, :longitude => 0)

        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='1' lat='2' changeset='#{changeset.id}' version='1'/>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :forbidden

        changeset.reload
        assert_equal 0, changeset.num_changes
        node.reload
        assert_equal 1, node.version
        assert_equal 0, node.latitude
        assert_equal 0, node.longitude
      end

      def test_upload_without_required_scope
        user = create(:user)
        changeset = create(:changeset, :user => user)
        node = create(:node, :latitude => 0, :longitude => 0)

        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='1' lat='2' changeset='#{changeset.id}' version='1'/>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header user, :scopes => %w[read_prefs]

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :forbidden

        changeset.reload
        assert_equal 0, changeset.num_changes
        node.reload
        assert_equal 1, node.version
        assert_equal 0, node.latitude
        assert_equal 0, node.longitude
      end

      def test_upload_with_required_scope
        user = create(:user)
        changeset = create(:changeset, :user => user)
        node = create(:node, :latitude => 0, :longitude => 0)

        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='1' lat='2' changeset='#{changeset.id}' version='1'/>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header user, :scopes => %w[write_api]

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :success

        assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
          assert_dom "> node", 1 do
            assert_dom "> @old_id", node.id.to_s
            assert_dom "> @new_id", node.id.to_s
            assert_dom "> @new_version", "2"
          end
        end

        changeset.reload
        assert_equal 1, changeset.num_changes
        node.reload
        assert_equal 2, node.version
        assert_equal 2 * GeoRecord::SCALE, node.latitude
        assert_equal 1 * GeoRecord::SCALE, node.longitude
      end

      ##
      # try to upload with commands other than create, modify, or delete
      def test_upload_unknown_action
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <ping>
              <node id='1' lon='1' lat='1' changeset='#{changeset.id}' />
            </ping>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :bad_request
        assert_equal "Unknown action ping, choices are create, modify, delete", @response.body
      end

      ##
      # test for issues in https://github.com/openstreetmap/trac-tickets/issues/1568
      def test_upload_empty_changeset
        changeset = create(:changeset)

        auth_header = bearer_authorization_header changeset.user

        ["<osmChange/>",
         "<osmChange></osmChange>",
         "<osmChange><modify/></osmChange>",
         "<osmChange><modify></modify></osmChange>"].each do |diff|
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :success
        end
      end

      ##
      # test that the X-Error-Format header works to request XML errors
      def test_upload_xml_errors
        changeset = create(:changeset)
        node = create(:node)
        create(:relation_member, :member => node)

        # try and delete a node that is in use
        diff = XML::Document.new
        diff.root = XML::Node.new "osmChange"
        delete = XML::Node.new "delete"
        diff.root << delete
        delete << xml_node_for_node(node)

        auth_header = bearer_authorization_header changeset.user
        error_header = error_format_header "xml"

        post api_changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header.merge(error_header)

        assert_response :success

        assert_dom "osmError[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1
        assert_dom "osmError>status", 1
        assert_dom "osmError>message", 1
      end

      # -------------------------------------
      # Test creating elements.
      # -------------------------------------

      def test_upload_create_elements
        user = create(:user)
        changeset = create(:changeset, :user => user)
        node = create(:node)
        way = create(:way_with_nodes, :nodes_count => 2)
        relation = create(:relation)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
                <tag k='foo' v='bar'/>
                <tag k='baz' v='bat'/>
              </node>
              <way id='-1' changeset='#{changeset.id}'>
                <nd ref='#{node.id}'/>
              </way>
            </create>
            <create>
              <relation id='-1' changeset='#{changeset.id}'>
                <member type='way' role='some' ref='#{way.id}'/>
                <member type='node' role='some' ref='#{node.id}'/>
                <member type='relation' role='some' ref='#{relation.id}'/>
              </relation>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :success

        new_node_id, new_way_id, new_rel_id = nil
        assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
          # inspect the response to find out what the new element IDs are
          # check the old IDs are all present and negative one
          # check the versions are present and equal one
          assert_dom "> node", 1 do |(node_el)|
            new_node_id = node_el["new_id"].to_i
            assert_dom "> @old_id", "-1"
            assert_dom "> @new_version", "1"
          end
          assert_dom "> way", 1 do |(way_el)|
            new_way_id = way_el["new_id"].to_i
            assert_dom "> @old_id", "-1"
            assert_dom "> @new_version", "1"
          end
          assert_dom "> relation", 1 do |(rel_el)|
            new_rel_id = rel_el["new_id"].to_i
            assert_dom "> @old_id", "-1"
            assert_dom "> @new_version", "1"
          end
        end

        assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
        assert_equal 0, Way.find(new_way_id).tags.size, "new way should have no tags"
        assert_equal 0, Relation.find(new_rel_id).tags.size, "new relation should have no tags"
      end

      ##
      # upload an element with a really long tag value
      def test_upload_create_node_with_tag_too_long
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
                <tag k='foo' v='#{'x' * 256}'/>
              </node>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_no_difference "Node.count" do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :bad_request
        end
      end

      def test_upload_create_nodes_with_invalid_placeholder_reuse_in_one_action_block
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
              <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_no_difference "Node.count" do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :bad_request
        end
      end

      def test_upload_create_nodes_with_invalid_placeholder_reuse_in_two_action_blocks
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/>
            </create>
            <create>
              <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_no_difference "Node.count" do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :bad_request
        end
      end

      def test_upload_create_way_referring_node_placeholder_defined_later
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <way id="-1" changeset="#{changeset.id}">
                <nd ref="-1"/>
              </way>
              <node id="-1" lat="1" lon="2" changeset="#{changeset.id}"/>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_no_difference "Node.count" do
          assert_no_difference "Way.count" do
            post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

            assert_response :bad_request
          end
        end
        assert_equal "Placeholder node not found for reference -1 in way -1", @response.body
      end

      def test_upload_create_way_referring_undefined_node_placeholder
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <way id="-1" changeset="#{changeset.id}">
                <nd ref="-1"/>
              </way>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_no_difference "Way.count" do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :bad_request
        end
        assert_equal "Placeholder node not found for reference -1 in way -1", @response.body
      end

      def test_upload_create_existing_way_referring_undefined_node_placeholder
        changeset = create(:changeset)
        way = create(:way)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <way id="#{way.id}" changeset="#{changeset.id}" version="1">
                <nd ref="-1"/>
              </way>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :bad_request
        assert_equal "Placeholder node not found for reference -1 in way #{way.id}", @response.body

        way.reload
        assert_equal 1, way.version
      end

      def test_upload_create_relation_referring_undefined_node_placeholder
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <relation id="-1" changeset="#{changeset.id}" version="1">
                <member type="node" role="foo" ref="-1"/>
              </relation>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_no_difference "Relation.count" do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :bad_request
        end
        assert_equal "Placeholder Node not found for reference -1 in relation -1.", @response.body
      end

      def test_upload_create_existing_relation_referring_undefined_way_placeholder
        changeset = create(:changeset)
        relation = create(:relation)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <relation id="#{relation.id}" changeset="#{changeset.id}" version="1">
                <member type="way" role="bar" ref="-1"/>
              </relation>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :bad_request
        assert_equal "Placeholder Way not found for reference -1 in relation #{relation.id}.", @response.body

        relation.reload
        assert_equal 1, relation.version
      end

      def test_upload_create_relations_with_circular_references
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange version='0.6'>
            <create>
              <relation id='-2' version='0' changeset='#{changeset.id}'>
                <member type='relation' role='' ref='-4' />
                <tag k='type' v='route' />
                <tag k='name' v='AtoB' />
              </relation>
              <relation id='-3' version='0' changeset='#{changeset.id}'>
                <tag k='type' v='route' />
                <tag k='name' v='BtoA' />
              </relation>
              <relation id='-4' version='0' changeset='#{changeset.id}'>
                <member type='relation' role='' ref='-2' />
                <member type='relation' role='' ref='-3' />
                <tag k='type' v='route_master' />
                <tag k='name' v='master' />
              </relation>
            </create>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header

        assert_response :bad_request
        assert_equal "Placeholder Relation not found for reference -4 in relation -2.", @response.body
      end

      # -------------------------------------
      # Test modifying elements.
      # -------------------------------------

      def test_upload_modify_elements
        user = create(:user)
        changeset = create(:changeset, :user => user)
        node = create(:node, :latitude => 0, :longitude => 0)
        way = create(:way)
        relation = create(:relation)
        other_relation = create(:relation)

        # create some tags, since we test that they are removed later
        create(:node_tag, :node => node)
        create(:way_tag, :way => way)
        create(:relation_tag, :relation => relation)

        # simple diff to change a node, way and relation by removing their tags
        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='1' lat='2' changeset='#{changeset.id}' version='1'/>
              <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
                <nd ref='#{node.id}'/>
              </way>
            </modify>
            <modify>
              <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
                <member type='way' role='some' ref='#{way.id}'/>
                <member type='node' role='some' ref='#{node.id}'/>
                <member type='relation' role='some' ref='#{other_relation.id}'/>
              </relation>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :success

        assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
          assert_dom "> node", 1 do
            assert_dom "> @old_id", node.id.to_s
            assert_dom "> @new_id", node.id.to_s
            assert_dom "> @new_version", "2"
          end
          assert_dom "> way", 1 do
            assert_dom "> @old_id", way.id.to_s
            assert_dom "> @new_id", way.id.to_s
            assert_dom "> @new_version", "2"
          end
          assert_dom "> relation", 1 do
            assert_dom "> @old_id", relation.id.to_s
            assert_dom "> @new_id", relation.id.to_s
            assert_dom "> @new_version", "2"
          end
        end

        changeset.reload
        assert_equal 3, changeset.num_changes
        node.reload
        assert_equal 2, node.version
        assert_equal 2 * GeoRecord::SCALE, node.latitude
        assert_equal 1 * GeoRecord::SCALE, node.longitude
        assert_equal 0, node.tags.size, "node #{node.id} should now have no tags"
        way.reload
        assert_equal 2, way.version
        assert_equal 0, way.tags.size, "way #{way.id} should now have no tags"
        assert_equal [node], way.nodes
        relation.reload
        assert_equal 2, relation.version
        assert_equal 0, relation.tags.size, "relation #{relation.id} should now have no tags"
        assert_equal [["Way", way.id, "some"], ["Node", node.id, "some"], ["Relation", other_relation.id, "some"]], relation.members
      end

      ##
      # upload multiple versions of the same element in the same diff.
      def test_upload_modify_multiple_node_versions
        node = create(:node)
        changeset = create(:changeset)

        # change the location of a node multiple times, each time referencing
        # the last version. doesn't this depend on version numbers being
        # sequential?
        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='0.0' lat='0.0' changeset='#{changeset.id}' version='1'/>
              <node id='#{node.id}' lon='0.1' lat='0.0' changeset='#{changeset.id}' version='2'/>
              <node id='#{node.id}' lon='0.1' lat='0.1' changeset='#{changeset.id}' version='3'/>
              <node id='#{node.id}' lon='0.1' lat='0.2' changeset='#{changeset.id}' version='4'/>
              <node id='#{node.id}' lon='0.2' lat='0.2' changeset='#{changeset.id}' version='5'/>
              <node id='#{node.id}' lon='0.3' lat='0.2' changeset='#{changeset.id}' version='6'/>
              <node id='#{node.id}' lon='0.3' lat='0.3' changeset='#{changeset.id}' version='7'/>
              <node id='#{node.id}' lon='0.9' lat='0.9' changeset='#{changeset.id}' version='8'/>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :success

        assert_dom "diffResult>node", 8

        node.reload
        assert_equal 9, node.version
        assert_equal 0.9 * GeoRecord::SCALE, node.latitude
        assert_equal 0.9 * GeoRecord::SCALE, node.longitude
      end

      ##
      # upload multiple versions of the same element in the same diff, but
      # keep the version numbers the same.
      def test_upload_modify_duplicate_node_versions
        node = create(:node, :latitude => 0, :longitude => 0)
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
              <node id='#{node.id}' lon='2' lat='2' changeset='#{changeset.id}' version='1'/>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :conflict

        node.reload
        assert_equal 1, node.version
        assert_equal 0, node.latitude
        assert_equal 0, node.longitude
      end

      ##
      # try to upload some elements without specifying the version
      def test_upload_modify_missing_node_version
        node = create(:node, :latitude => 0, :longitude => 0)
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}'/>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :bad_request

        node.reload
        assert_equal 1, node.version
        assert_equal 0, node.latitude
        assert_equal 0, node.longitude
      end

      ##
      # create a diff which references several changesets, which should cause
      # a rollback and none of the diff gets committed
      def test_upload_modify_with_references_to_different_changesets
        changeset1 = create(:changeset)
        changeset2 = create(:changeset, :user => changeset1.user)
        node1 = create(:node)
        node2 = create(:node)

        # simple diff to create a node way and relation using placeholders
        diff = <<~CHANGESET
          <osmChange>
            <modify>
              <node id='#{node1.id}' lon='0' lat='0' changeset='#{changeset1.id}' version='1'/>
            </modify>
            <modify>
              <node id='#{node2.id}' lon='0' lat='0' changeset='#{changeset2.id}' version='1'/>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset1.user

        post api_changeset_upload_path(changeset1), :params => diff, :headers => auth_header

        assert_response :conflict

        assert_nodes_are_equal(node1, Node.find(node1.id))
        assert_nodes_are_equal(node2, Node.find(node2.id))
      end

      ##
      # upload a valid changeset which has a mixture of whitespace
      # to check a bug https://github.com/openstreetmap/trac-tickets/issues/1565
      def test_upload_modify_with_mixed_whitespace
        changeset = create(:changeset)
        node = create(:node)
        way = create(:way_with_nodes, :nodes_count => 2)
        relation = create(:relation)
        other_relation = create(:relation)
        create(:relation_tag, :relation => relation)

        diff = <<~CHANGESET
          <osmChange>
          <modify><node id='#{node.id}' lon='0' lat='0' changeset='#{changeset.id}'
            version='1'></node>
            <node id='#{node.id}' lon='1' lat='1' changeset='#{changeset.id}' version='2'><tag k='k' v='v'/></node></modify>
          <modify>
          <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'><member
            type='way' role='some' ref='#{way.id}'/><member
              type='node' role='some' ref='#{node.id}'/>
            <member type='relation' role='some' ref='#{other_relation.id}'/>
            </relation>
          </modify></osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :success

        assert_dom "diffResult>node", 2
        assert_dom "diffResult>relation", 1

        assert_equal 1, Node.find(node.id).tags.size, "node #{node.id} should now have one tag"
        assert_equal 0, Relation.find(relation.id).tags.size, "relation #{relation.id} should now have no tags"
      end

      def test_upload_modify_unknown_node_placeholder
        check_upload_results_in_not_found do |changeset|
          "<modify><node id='-1' lon='0' lat='0' changeset='#{changeset.id}' version='1'/></modify>"
        end
      end

      def test_upload_modify_unknown_way_placeholder
        check_upload_results_in_not_found do |changeset|
          "<modify><way id='-1' changeset='#{changeset.id}' version='1'/></modify>"
        end
      end

      def test_upload_modify_unknown_relation_placeholder
        check_upload_results_in_not_found do |changeset|
          "<modify><relation id='-1' changeset='#{changeset.id}' version='1'/></modify>"
        end
      end

      # -------------------------------------
      # Test deleting elements.
      # -------------------------------------

      ##
      # test a complex delete where we delete elements which rely on each other
      # in the same transaction.
      def test_upload_delete_elements
        changeset = create(:changeset)
        super_relation = create(:relation)
        used_relation = create(:relation)
        used_way = create(:way)
        used_node = create(:node)
        create(:relation_member, :relation => super_relation, :member => used_relation)
        create(:relation_member, :relation => super_relation, :member => used_way)
        create(:relation_member, :relation => super_relation, :member => used_node)

        diff = XML::Document.new
        diff.root = XML::Node.new "osmChange"
        delete = XML::Node.new "delete"
        diff.root << delete
        delete << xml_node_for_relation(super_relation)
        delete << xml_node_for_relation(used_relation)
        delete << xml_node_for_way(used_way)
        delete << xml_node_for_node(used_node)
        %w[node way relation].each do |type|
          delete.find("//osmChange/delete/#{type}").each do |n|
            n["changeset"] = changeset.id.to_s
          end
        end

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header

        assert_response :success

        assert_dom "diffResult", 1 do
          assert_dom "> node", 1
          assert_dom "> way", 1
          assert_dom "> relation", 2
        end

        assert_not Node.find(used_node.id).visible
        assert_not Way.find(used_way.id).visible
        assert_not Relation.find(super_relation.id).visible
        assert_not Relation.find(used_relation.id).visible
      end

      ##
      # test uploading a delete with no lat/lon, as they are optional in the osmChange spec.
      def test_upload_delete_node_without_latlon
        node = create(:node)
        changeset = create(:changeset)

        diff = "<osmChange><delete><node id='#{node.id}' version='#{node.version}' changeset='#{changeset.id}'/></delete></osmChange>"

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :success

        assert_dom "diffResult", 1 do
          assert_dom "> node", 1 do
            assert_dom "> @old_id", node.id.to_s
            assert_dom "> @new_id", 0
            assert_dom "> @new_version", 0
          end
        end

        node.reload
        assert_not node.visible
      end

      ##
      # test that deleting stuff in a transaction doesn't bypass the checks
      # to ensure that used elements are not deleted.
      def test_upload_delete_referenced_elements
        changeset = create(:changeset)
        relation = create(:relation)
        other_relation = create(:relation)
        used_way = create(:way)
        used_node = create(:node)
        create(:relation_member, :relation => relation, :member => used_way)
        create(:relation_member, :relation => relation, :member => used_node)

        diff = XML::Document.new
        diff.root = XML::Node.new "osmChange"
        delete = XML::Node.new "delete"
        diff.root << delete
        delete << xml_node_for_relation(other_relation)
        delete << xml_node_for_way(used_way)
        delete << xml_node_for_node(used_node)
        %w[node way relation].each do |type|
          delete.find("//osmChange/delete/#{type}").each do |n|
            n["changeset"] = changeset.id.to_s
          end
        end

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header

        assert_response :precondition_failed
        assert_equal "Precondition failed: Way #{used_way.id} is still used by relations #{relation.id}.", @response.body

        assert Node.find(used_node.id).visible
        assert Way.find(used_way.id).visible
        assert Relation.find(relation.id).visible
        assert Relation.find(other_relation.id).visible
      end

      ##
      # test that a conditional delete of an in use object works.
      def test_upload_delete_if_unused
        changeset = create(:changeset)
        super_relation = create(:relation)
        used_relation = create(:relation)
        used_way = create(:way)
        used_node = create(:node)
        create(:relation_member, :relation => super_relation, :member => used_relation)
        create(:relation_member, :relation => super_relation, :member => used_way)
        create(:relation_member, :relation => super_relation, :member => used_node)

        diff = XML::Document.new
        diff.root = XML::Node.new "osmChange"
        delete = XML::Node.new "delete"
        diff.root << delete
        delete["if-unused"] = ""
        delete << xml_node_for_relation(used_relation)
        delete << xml_node_for_way(used_way)
        delete << xml_node_for_node(used_node)
        %w[node way relation].each do |type|
          delete.find("//osmChange/delete/#{type}").each do |n|
            n["changeset"] = changeset.id.to_s
          end
        end

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header

        assert_response :success

        assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
          assert_dom "> node", 1 do
            assert_dom "> @old_id", used_node.id.to_s
            assert_dom "> @new_id", used_node.id.to_s
            assert_dom "> @new_version", used_node.version.to_s
          end
          assert_dom "> way", 1 do
            assert_dom "> @old_id", used_way.id.to_s
            assert_dom "> @new_id", used_way.id.to_s
            assert_dom "> @new_version", used_way.version.to_s
          end
          assert_dom "> relation", 1 do
            assert_dom "> @old_id", used_relation.id.to_s
            assert_dom "> @new_id", used_relation.id.to_s
            assert_dom "> @new_version", used_relation.version.to_s
          end
        end

        assert Node.find(used_node.id).visible
        assert Way.find(used_way.id).visible
        assert Relation.find(used_relation.id).visible
      end

      def test_upload_delete_with_multiple_blocks_and_if_unused
        changeset = create(:changeset)
        node = create(:node)
        way = create(:way)
        create(:way_node, :way => way, :node => node)
        alone_node = create(:node)

        diff = <<~CHANGESET
          <osmChange version='0.6'>
            <delete version="0.6">
              <node id="#{node.id}" version="#{node.version}" changeset="#{changeset.id}"/>
            </delete>
            <delete version="0.6" if-unused="true">
              <node id="#{alone_node.id}" version="#{alone_node.version}" changeset="#{changeset.id}"/>
            </delete>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff.to_s, :headers => auth_header

        assert_response :precondition_failed

        assert_equal "Precondition failed: Node #{node.id} is still used by ways #{way.id}.", @response.body
      end

      def test_upload_delete_unknown_node_placeholder
        check_upload_results_in_not_found do |changeset|
          "<delete><node id='-1' changeset='#{changeset.id}' version='1'/></delete>"
        end
      end

      def test_upload_delete_unknown_way_placeholder
        check_upload_results_in_not_found do |changeset|
          "<delete><way id='-1' changeset='#{changeset.id}' version='1'/></delete>"
        end
      end

      def test_upload_delete_unknown_relation_placeholder
        check_upload_results_in_not_found do |changeset|
          "<delete><relation id='-1' changeset='#{changeset.id}' version='1'/></delete>"
        end
      end

      # -------------------------------------
      # Test combined element changes.
      # -------------------------------------

      ##
      # upload something which creates new objects and inserts them into
      # existing containers using placeholders.
      def test_upload_create_and_insert_elements
        way = create(:way)
        node = create(:node)
        relation = create(:relation)
        create(:way_node, :way => way, :node => node)
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
                <tag k='foo' v='bar'/>
                <tag k='baz' v='bat'/>
              </node>
            </create>
            <modify>
              <way id='#{way.id}' changeset='#{changeset.id}' version='1'>
                <nd ref='-1'/>
                <nd ref='#{node.id}'/>
              </way>
              <relation id='#{relation.id}' changeset='#{changeset.id}' version='1'>
                <member type='way' role='some' ref='#{way.id}'/>
                <member type='node' role='some' ref='-1'/>
                <member type='relation' role='some' ref='#{relation.id}'/>
              </relation>
            </modify>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :success

        new_node_id = nil
        assert_dom "diffResult[version='#{Settings.api_version}'][generator='#{Settings.generator}']", 1 do
          assert_dom "> node", 1 do |(node_el)|
            new_node_id = node_el["new_id"].to_i
          end
          assert_dom "> way", 1
          assert_dom "> relation", 1
        end

        assert_equal 2, Node.find(new_node_id).tags.size, "new node should have two tags"
        assert_equal [new_node_id, node.id], Way.find(way.id).nds, "way nodes should match"
        Relation.find(relation.id).members.each do |type, id, _role|
          assert_equal new_node_id, id, "relation should contain new node" if type == "node"
        end
      end

      ##
      # test that a placeholder can be reused within the same upload.
      def test_upload_create_modify_delete_node_reusing_placeholder
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id='-1' lon='0' lat='0' changeset='#{changeset.id}'>
                <tag k="foo" v="bar"/>
              </node>
            </create>
            <modify>
              <node id='-1' lon='1' lat='1' changeset='#{changeset.id}' version='1'/>
            </modify>
            <delete>
              <node id='-1' lon='2' lat='2' changeset='#{changeset.id}' version='2'/>
            </delete>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_difference "Node.count", 1 do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :success
        end

        assert_dom "diffResult>node", 3
        assert_dom "diffResult>node[old_id='-1']", 3

        node = Node.last
        assert_equal 3, node.version
        assert_not node.visible
      end

      def test_upload_create_and_duplicate_delete
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id="-1" lat="39" lon="116" changeset="#{changeset.id}" />
            </create>
            <delete>
              <node id="-1" version="1" changeset="#{changeset.id}" />
              <node id="-1" version="1" changeset="#{changeset.id}" />
            </delete>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_no_difference "Node.count" do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :gone
        end
      end

      def test_upload_create_and_duplicate_delete_if_unused
        changeset = create(:changeset)

        diff = <<~CHANGESET
          <osmChange>
            <create>
              <node id="-1" lat="39" lon="116" changeset="#{changeset.id}" />
            </create>
            <delete if-unused="true">
              <node id="-1" version="1" changeset="#{changeset.id}" />
              <node id="-1" version="1" changeset="#{changeset.id}" />
            </delete>
          </osmChange>
        CHANGESET

        auth_header = bearer_authorization_header changeset.user

        assert_difference "Node.count", 1 do
          post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

          assert_response :success
        end

        assert_dom "diffResult>node", 3
        assert_dom "diffResult>node[old_id='-1']", 3
        assert_dom "diffResult>node[new_version='1']", 1
        assert_dom "diffResult>node[new_version='2']", 1

        node = Node.last
        assert_equal 2, node.version
        assert_not node.visible
      end

      private

      def check_upload_results_in_not_found(&)
        changeset = create(:changeset)
        diff = "<osmChange>#{yield changeset}</osmChange>"
        auth_header = bearer_authorization_header changeset.user

        post api_changeset_upload_path(changeset), :params => diff, :headers => auth_header

        assert_response :not_found
        changeset.reload
        assert_equal 0, changeset.num_changes
      end
    end
  end
end
