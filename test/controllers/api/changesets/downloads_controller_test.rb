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

      def test_show
        changeset = create(:changeset)
        node = create(:node, :with_history, :version => 1, :changeset => changeset)
        tag = create(:old_node_tag, :old_node => node.old_nodes.find_by(:version => 1))
        node2 = create(:node, :with_history, :version => 1, :changeset => changeset)
        _node3 = create(:node, :with_history, :deleted, :version => 1, :changeset => changeset)
        _relation = create(:relation, :with_history, :version => 1, :changeset => changeset)
        _relation2 = create(:relation, :with_history, :deleted, :version => 1, :changeset => changeset)

        get api_changeset_download_path(changeset)

        assert_response :success
        # FIXME: needs more assert_select tests
        assert_select "osmChange[version='#{Settings.api_version}'][generator='#{Settings.generator}']" do
          assert_select "create", :count => 5
          assert_select "create>node[id='#{node.id}'][visible='#{node.visible?}'][version='#{node.version}']" do
            assert_select "tag[k='#{tag.k}'][v='#{tag.v}']"
          end
          assert_select "create>node[id='#{node2.id}']"
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
