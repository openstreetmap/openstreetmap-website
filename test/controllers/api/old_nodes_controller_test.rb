require "test_helper"

module Api
  class OldNodesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/node/1/history", :method => :get },
        { :controller => "api/old_nodes", :action => "index", :node_id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1/history.json", :method => :get },
        { :controller => "api/old_nodes", :action => "index", :node_id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1/2", :method => :get },
        { :controller => "api/old_nodes", :action => "show", :node_id => "1", :version => "2" }
      )
      assert_routing(
        { :path => "/api/0.6/node/1/2.json", :method => :get },
        { :controller => "api/old_nodes", :action => "show", :node_id => "1", :version => "2", :format => "json" }
      )
    end

    def test_index
      node = create(:node, :version => 2)
      create(:old_node, :node_id => node.id, :version => 1, :latitude => 60 * OldNode::SCALE, :longitude => 30 * OldNode::SCALE)
      create(:old_node, :node_id => node.id, :version => 2, :latitude => 61 * OldNode::SCALE, :longitude => 31 * OldNode::SCALE)

      get api_node_versions_path(node)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> node", 2 do |dom_nodes|
          assert_dom dom_nodes[0], "> @id", node.id.to_s
          assert_dom dom_nodes[0], "> @version", "1"
          assert_dom dom_nodes[0], "> @lat", "60.0000000"
          assert_dom dom_nodes[0], "> @lon", "30.0000000"

          assert_dom dom_nodes[1], "> @id", node.id.to_s
          assert_dom dom_nodes[1], "> @version", "2"
          assert_dom dom_nodes[1], "> @lat", "61.0000000"
          assert_dom dom_nodes[1], "> @lon", "31.0000000"
        end
      end
    end

    ##
    # test that redacted nodes aren't visible in the history
    def test_index_redacted_unauthorised
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_node_versions_path(node)

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm node[id='#{node.id}'][version='1']", 0,
                 "redacted node #{node.id} version 1 shouldn't be present in the history."

      get api_node_versions_path(node, :show_redactions => "true")

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm node[id='#{node.id}'][version='1']", 0,
                 "redacted node #{node.id} version 1 shouldn't be present in the history when passing flag."
    end

    def test_index_redacted_normal_user
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_node_versions_path(node), :headers => bearer_authorization_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm node[id='#{node.id}'][version='1']", 0,
                 "redacted node #{node.id} version 1 shouldn't be present in the history, even when logged in."

      get api_node_versions_path(node, :show_redactions => "true"), :headers => bearer_authorization_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm node[id='#{node.id}'][version='1']", 0,
                 "redacted node #{node.id} version 1 shouldn't be present in the history, even when logged in and passing flag."
    end

    def test_index_redacted_moderator
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_node_versions_path(node), :headers => auth_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm node[id='#{node.id}'][version='1']", 0,
                 "node #{node.id} version 1 should not be present in the history for moderators when not passing flag."

      get api_node_versions_path(node, :show_redactions => "true"), :headers => auth_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm node[id='#{node.id}'][version='1']", 1,
                 "node #{node.id} version 1 should still be present in the history for moderators when passing flag."
    end

    def test_show
      node = create(:node, :version => 2)
      create(:old_node, :node_id => node.id, :version => 1, :latitude => 60 * OldNode::SCALE, :longitude => 30 * OldNode::SCALE)
      create(:old_node, :node_id => node.id, :version => 2, :latitude => 61 * OldNode::SCALE, :longitude => 31 * OldNode::SCALE)

      get api_node_version_path(node, 1)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> node", 1 do
          assert_dom "> @id", node.id.to_s
          assert_dom "> @version", "1"
          assert_dom "> @lat", "60.0000000"
          assert_dom "> @lon", "30.0000000"
        end
      end

      get api_node_version_path(node, 2)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> node", 1 do
          assert_dom "> @id", node.id.to_s
          assert_dom "> @version", "2"
          assert_dom "> @lat", "61.0000000"
          assert_dom "> @lon", "31.0000000"
        end
      end
    end

    def test_show_not_found
      check_not_found_id_version(70000, 312344)
      check_not_found_id_version(-1, -13)
      check_not_found_id_version(create(:node).id, 24354)
      check_not_found_id_version(24356, create(:node).version)
    end

    ##
    # test that redacted nodes aren't visible, regardless of
    # authorisation except as moderator...
    def test_show_redacted_unauthorised
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_node_version_path(node, 1)

      assert_response :forbidden, "Redacted node shouldn't be visible via the version API."

      get api_node_version_path(node, 1, :show_redactions => "true")

      assert_response :forbidden, "Redacted node shouldn't be visible via the version API when passing flag."
    end

    def test_show_redacted_normal_user
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

      get api_node_version_path(node, 1), :headers => bearer_authorization_header

      assert_response :forbidden, "Redacted node shouldn't be visible via the version API, even when logged in."

      get api_node_version_path(node, 1, :show_redactions => "true"), :headers => bearer_authorization_header

      assert_response :forbidden, "Redacted node shouldn't be visible via the version API, even when logged in and passing flag."
    end

    def test_show_redacted_moderator
      node = create(:node, :with_history, :version => 2)
      node.old_nodes.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_node_version_path(node, 1), :headers => auth_header

      assert_response :forbidden, "Redacted node should be gone for moderator, when flag not passed."

      get api_node_version_path(node, 1, :show_redactions => "true"), :headers => auth_header

      assert_response :success, "Redacted node should not be gone for moderator, when flag passed."
    end

    # Ensure the lat/lon is formatted as a decimal e.g. not 4.0e-05
    def test_lat_lon_xml_format
      old_node = create(:old_node, :latitude => (0.00004 * OldNode::SCALE).to_i, :longitude => (0.00008 * OldNode::SCALE).to_i)

      get api_node_versions_path(old_node.node_id)
      assert_match(/lat="0.0000400"/, response.body)
      assert_match(/lon="0.0000800"/, response.body)
    end

    private

    def check_not_found_id_version(id, version)
      get api_node_version_path(id, version)
      assert_response :not_found
    rescue ActionController::UrlGenerationError => e
      assert_match(/No route matches/, e.to_s)
    end
  end
end
