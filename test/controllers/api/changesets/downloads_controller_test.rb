require "test_helper"

module Api
  module Changesets
    class DownloadsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/changeset/1/download", :method => :get },
          { :controller => "api/changesets/downloads", :action => "show", :changeset_id => "1" }
        )
      end

      def test_show_empty
        changeset = create(:changeset)

        get api_changeset_download_path(changeset)

        assert_response :success
        assert_dom "osmChange[version='#{Settings.api_version}'][generator='#{Settings.generator}']" do
          assert_dom "create", 0
          assert_dom "modify", 0
          assert_dom "delete", 0
        end
      end

      def test_show_created_elements
        changeset = create(:changeset)
        old_node1 = create(:old_node, :changeset => changeset, :version => 1, :latitude => (60.12345 * OldNode::SCALE).to_i, :longitude => (30.54321 * OldNode::SCALE).to_i)
        create(:old_node_tag, :old_node => old_node1, :k => "highway", :v => "crossing")
        create(:old_node_tag, :old_node => old_node1, :k => "crossing", :v => "marked")
        old_node2 = create(:old_node, :changeset => changeset, :version => 1, :latitude => (60.23456 * OldNode::SCALE).to_i, :longitude => (30.65432 * OldNode::SCALE).to_i)
        create(:old_node_tag, :old_node => old_node2, :k => "highway", :v => "traffic_signals")
        old_way = create(:old_way, :changeset => changeset, :version => 1)
        create(:old_way_tag, :old_way => old_way, :k => "highway", :v => "secondary")
        create(:old_way_tag, :old_way => old_way, :k => "name", :v => "Some Street")
        create(:old_way_node, :old_way => old_way, :node => old_node1.current_node, :sequence_id => 1)
        create(:old_way_node, :old_way => old_way, :node => old_node2.current_node, :sequence_id => 2)
        old_relation = create(:old_relation, :changeset => changeset, :version => 1)
        create(:old_relation_tag, :old_relation => old_relation, :k => "type", :v => "restriction")
        create(:old_relation_member, :old_relation => old_relation, :member => old_way.current_way, :member_role => "from", :sequence_id => 1)
        create(:old_relation_member, :old_relation => old_relation, :member => old_node2.current_node, :member_role => "via", :sequence_id => 2)

        get api_changeset_download_path(changeset)

        assert_response :success
        assert_dom "osmChange[version='#{Settings.api_version}'][generator='#{Settings.generator}']" do
          assert_dom "create", 4 do
            assert_dom "node", 2
            assert_dom "node[id='#{old_node1.node_id}']", 1 do
              assert_dom "> @version", "1"
              assert_dom "> @visible", "true"
              assert_dom "tag", 2
              assert_dom "tag[k='highway'][v='crossing']"
              assert_dom "tag[k='crossing'][v='marked']"
              assert_dom "> @lat", "60.1234500"
              assert_dom "> @lon", "30.5432100"
            end
            assert_dom "node[id='#{old_node2.node_id}']", 1 do
              assert_dom "> @version", "1"
              assert_dom "> @visible", "true"
              assert_dom "tag", 1
              assert_dom "tag[k='highway'][v='traffic_signals']"
              assert_dom "> @lat", "60.2345600"
              assert_dom "> @lon", "30.6543200"
            end
            assert_dom "way", 1
            assert_dom "way[id='#{old_way.way_id}']", 1 do
              assert_dom "> @version", "1"
              assert_dom "> @visible", "true"
              assert_dom "tag", 2
              assert_dom "tag[k='highway'][v='secondary']"
              assert_dom "tag[k='name'][v='Some Street']"
              assert_dom "nd", 2 do |dom_nds|
                assert_dom dom_nds[0], "> @ref", old_node1.node_id.to_s
                assert_dom dom_nds[1], "> @ref", old_node2.node_id.to_s
              end
            end
            assert_dom "relation", 1
            assert_dom "relation[id='#{old_relation.relation_id}']", 1 do
              assert_dom "> @version", "1"
              assert_dom "> @visible", "true"
              assert_dom "tag", 1
              assert_dom "tag[k='type'][v='restriction']"
              assert_dom "member", 2 do |dom_members|
                assert_dom dom_members[0], "> @type", "way"
                assert_dom dom_members[0], "> @ref", old_way.way_id.to_s
                assert_dom dom_members[0], "> @role", "from"
                assert_dom dom_members[1], "> @type", "node"
                assert_dom dom_members[1], "> @ref", old_node2.node_id.to_s
                assert_dom dom_members[1], "> @role", "via"
              end
            end
          end
        end
      end

      def test_show_edited_elements
        changeset = create(:changeset)
        old_node1 = create(:old_node, :changeset => changeset, :version => 2, :latitude => (60.12345 * OldNode::SCALE).to_i, :longitude => (30.54321 * OldNode::SCALE).to_i)
        create(:old_node_tag, :old_node => old_node1, :k => "highway", :v => "crossing")
        create(:old_node_tag, :old_node => old_node1, :k => "crossing", :v => "marked")
        old_node2 = create(:old_node, :changeset => changeset, :version => 2, :latitude => (60.23456 * OldNode::SCALE).to_i, :longitude => (30.65432 * OldNode::SCALE).to_i)
        create(:old_node_tag, :old_node => old_node2, :k => "highway", :v => "traffic_signals")
        old_way = create(:old_way, :changeset => changeset, :version => 2)
        create(:old_way_tag, :old_way => old_way, :k => "highway", :v => "secondary")
        create(:old_way_tag, :old_way => old_way, :k => "name", :v => "Some Street")
        create(:old_way_node, :old_way => old_way, :node => old_node1.current_node, :sequence_id => 1)
        create(:old_way_node, :old_way => old_way, :node => old_node2.current_node, :sequence_id => 2)
        old_relation = create(:old_relation, :changeset => changeset, :version => 2)
        create(:old_relation_tag, :old_relation => old_relation, :k => "type", :v => "restriction")
        create(:old_relation_member, :old_relation => old_relation, :member => old_way.current_way, :member_role => "from", :sequence_id => 1)
        create(:old_relation_member, :old_relation => old_relation, :member => old_node2.current_node, :member_role => "via", :sequence_id => 2)

        get api_changeset_download_path(changeset)

        assert_response :success
        assert_dom "osmChange[version='#{Settings.api_version}'][generator='#{Settings.generator}']" do
          assert_dom "modify", 4 do
            assert_dom "node", 2
            assert_dom "node[id='#{old_node1.node_id}']", 1 do
              assert_dom "> @version", "2"
              assert_dom "> @visible", "true"
              assert_dom "tag", 2
              assert_dom "tag[k='highway'][v='crossing']"
              assert_dom "tag[k='crossing'][v='marked']"
              assert_dom "> @lat", "60.1234500"
              assert_dom "> @lon", "30.5432100"
            end
            assert_dom "node[id='#{old_node2.node_id}']", 1 do
              assert_dom "> @version", "2"
              assert_dom "> @visible", "true"
              assert_dom "tag", 1
              assert_dom "tag[k='highway'][v='traffic_signals']"
              assert_dom "> @lat", "60.2345600"
              assert_dom "> @lon", "30.6543200"
            end
            assert_dom "way", 1
            assert_dom "way[id='#{old_way.way_id}']", 1 do
              assert_dom "> @version", "2"
              assert_dom "> @visible", "true"
              assert_dom "tag", 2
              assert_dom "tag[k='highway'][v='secondary']"
              assert_dom "tag[k='name'][v='Some Street']"
              assert_dom "nd", 2 do |dom_nds|
                assert_dom dom_nds[0], "> @ref", old_node1.node_id.to_s
                assert_dom dom_nds[1], "> @ref", old_node2.node_id.to_s
              end
            end
            assert_dom "relation", 1
            assert_dom "relation[id='#{old_relation.relation_id}']", 1 do
              assert_dom "> @version", "2"
              assert_dom "> @visible", "true"
              assert_dom "tag", 1
              assert_dom "tag[k='type'][v='restriction']"
              assert_dom "member", 2 do |dom_members|
                assert_dom dom_members[0], "> @type", "way"
                assert_dom dom_members[0], "> @ref", old_way.way_id.to_s
                assert_dom dom_members[0], "> @role", "from"
                assert_dom dom_members[1], "> @type", "node"
                assert_dom dom_members[1], "> @ref", old_node2.node_id.to_s
                assert_dom dom_members[1], "> @role", "via"
              end
            end
          end
        end
      end

      def test_show_deleted_elements
        changeset = create(:changeset)
        old_node1 = create(:old_node, :changeset => changeset, :version => 3, :visible => false)
        old_node2 = create(:old_node, :changeset => changeset, :version => 3, :visible => false)
        old_way = create(:old_way, :changeset => changeset, :version => 3, :visible => false)
        old_relation = create(:old_relation, :changeset => changeset, :version => 3, :visible => false)

        get api_changeset_download_path(changeset)

        assert_response :success
        assert_dom "osmChange[version='#{Settings.api_version}'][generator='#{Settings.generator}']" do
          assert_dom "delete", 4 do
            assert_dom "node", 2
            assert_dom "node[id='#{old_node1.node_id}']", 1 do
              assert_dom "> @version", "3"
              assert_dom "> @visible", "false"
            end
            assert_dom "node[id='#{old_node2.node_id}']", 1 do
              assert_dom "> @version", "3"
              assert_dom "> @visible", "false"
            end
            assert_dom "way", 1
            assert_dom "way[id='#{old_way.way_id}']", 1 do
              assert_dom "> @version", "3"
              assert_dom "> @visible", "false"
            end
            assert_dom "relation", 1
            assert_dom "relation[id='#{old_relation.relation_id}']", 1 do
              assert_dom "> @version", "3"
              assert_dom "> @visible", "false"
            end
          end
        end
      end

      def test_show_should_sort_by_timestamp
        changeset = create(:changeset)
        node1 = create(:old_node, :version => 2, :timestamp => "2020-02-01", :changeset => changeset)
        node0 = create(:old_node, :version => 2, :timestamp => "2020-01-01", :changeset => changeset)

        get api_changeset_download_path(changeset)

        assert_response :success
        assert_dom "modify", :count => 2 do |modify|
          assert_dom modify[0], ">node", :count => 1 do |node|
            assert_dom node, ">@id", node0.node_id.to_s
          end
          assert_dom modify[1], ">node", :count => 1 do |node|
            assert_dom node, ">@id", node1.node_id.to_s
          end
        end
      end

      def test_show_should_sort_by_version
        changeset = create(:changeset)
        node1 = create(:old_node, :version => 3, :timestamp => "2020-01-01", :changeset => changeset)
        node0 = create(:old_node, :version => 2, :timestamp => "2020-01-01", :changeset => changeset)

        get api_changeset_download_path(changeset)

        assert_response :success
        assert_dom "modify", :count => 2 do |modify|
          assert_dom modify[0], ">node", :count => 1 do |node|
            assert_dom node, ">@id", node0.node_id.to_s
          end
          assert_dom modify[1], ">node", :count => 1 do |node|
            assert_dom node, ">@id", node1.node_id.to_s
          end
        end
      end

      ##
      # check that the changeset download for a changeset with a redacted
      # element in it doesn't contain that element.
      def test_show_redacted
        changeset = create(:changeset)
        node = create(:node, :with_history, :version => 2, :changeset => changeset)
        node_v1 = node.old_nodes.find_by(:version => 1)
        node_v1.redact!(create(:redaction))

        get api_changeset_download_path(changeset)
        assert_response :success

        assert_select "osmChange", 1
        # this changeset contains the node in versions 1 & 2, but 1 should
        # be hidden.
        assert_select "osmChange node[id='#{node.id}']", 1
        assert_select "osmChange node[id='#{node.id}'][version='1']", 0
      end
    end
  end
end
