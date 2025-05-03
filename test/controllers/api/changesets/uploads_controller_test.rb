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
    end
  end
end
