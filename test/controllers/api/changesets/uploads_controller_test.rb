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
