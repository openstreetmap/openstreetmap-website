require "test_helper"

class OldNodesControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/node/1/history/2", :method => :get },
      { :controller => "old_nodes", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_visible
    node = create(:node, :with_history)
    get old_node_path(node, 1)
    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
  end

  def test_not_found
    get old_node_path(0, 0)
    assert_response :not_found
    assert_template "old_nodes/not_found"
    assert_template :layout => "map"
    assert_select "#sidebar_content", /node #0 version 0 could not be found/
  end
end
