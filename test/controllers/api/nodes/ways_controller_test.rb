require "test_helper"

module Api
  module Nodes
    class WaysControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/node/1/ways", :method => :get },
          { :controller => "api/nodes/ways", :action => "index", :node_id => "1" }
        )
        assert_routing(
          { :path => "/api/0.6/node/1/ways.json", :method => :get },
          { :controller => "api/nodes/ways", :action => "index", :node_id => "1", :format => "json" }
        )
      end

      ##
      # test that a call to ways_for_node returns all ways that contain the node
      # and none that don't.
      def test_index
        node = create(:node)
        way1 = create(:way)
        way2 = create(:way)
        create(:way_node, :way => way1, :node => node)
        create(:way_node, :way => way2, :node => node)
        # create an unrelated way
        create(:way_with_nodes, :nodes_count => 2)
        # create a way which used to use the node
        way3_v1 = create(:old_way, :version => 1)
        _way3_v2 = create(:old_way, :current_way => way3_v1.current_way, :version => 2)
        create(:old_way_node, :old_way => way3_v1, :node => node)

        get api_node_ways_path(node)
        assert_response :success
        ways_xml = XML::Parser.string(@response.body).parse
        assert_not_nil ways_xml, "failed to parse ways_for_node response"

        # check that the set of IDs match expectations
        expected_way_ids = [way1.id,
                            way2.id]
        found_way_ids = ways_xml.find("//osm/way").collect { |w| w["id"].to_i }
        assert_equal expected_way_ids.sort, found_way_ids.sort,
                     "expected ways for node #{node.id} did not match found"

        # check the full ways to ensure we're not missing anything
        expected_way_ids.each do |id|
          way_xml = ways_xml.find("//osm/way[@id='#{id}']").first
          assert_ways_are_equal(Way.find(id),
                                Way.from_xml_node(way_xml))
        end
      end

      def test_index_json
        node = create(:node)
        way = create(:way)
        create(:way_node, :way => way, :node => node)

        get api_node_ways_path(node, :format => "json")

        assert_response :success
        js = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil js
        assert_equal 1, js["elements"].count
        js_ways = js["elements"].filter { |e| e["type"] == "way" }
        assert_equal 1, js_ways.count
        assert_equal way.id, js_ways[0]["id"]
      end
    end
  end
end
