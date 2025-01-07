require "test_helper"

class NodesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/node/1", :method => :get },
      { :controller => "nodes", :action => "show", :id => "1" }
    )
  end

  def test_show
    node = create(:node)
    sidebar_browse_check :node_path, node.id, "elements/show"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :text => "1", :count => 1
    end
    assert_select ".secondary-actions a[href='#{api_node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{node_history_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 0
  end

  def test_show_multiple_versions
    node = create(:node, :with_history, :version => 2)
    sidebar_browse_check :node_path, node.id, "elements/show"
    assert_select ".secondary-actions a[href='#{node_history_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 2}']", :count => 1
  end

  def test_show_relation_member
    member = create(:node)
    relation = create(:relation)
    create(:relation_member, :relation => relation, :member => member)
    sidebar_browse_check :node_path, member.id, "elements/show"
    assert_select "a[href='#{relation_path relation}']", :count => 1
  end

  def test_show_deleted
    node = create(:node, :visible => false)
    sidebar_browse_check :node_path, node.id, "elements/show"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :text => "1", :count => 1
    end
    assert_select "a[href='#{api_node_path node}']", :count => 0
  end

  def test_show_redacted
    node = create(:node, :with_history, :deleted, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v1.redact!(create(:redaction))

    get node_path(node)
    assert_response :success
    assert_template "elements/show"

    # check that we don't show lat/lon for a redacted node.
    assert_select ".browse-section", 1
    assert_select ".browse-section.browse-node", 1
    assert_select ".browse-section.browse-node .latitude", 0
    assert_select ".browse-section.browse-node .longitude", 0
  end

  def test_show_secondary_actions_to_anonymous_user
    node = create(:node, :with_history)
    get node_path(node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 0
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_show_secondary_actions_to_regular_user
    session_for(create(:user))
    node = create(:node, :with_history)
    get node_path(node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 0
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_show_secondary_actions_to_moderator
    session_for(create(:moderator_user))
    node = create(:node, :with_history)
    get node_path(node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 0
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 1
  end

  def test_show_timeout
    node = create(:node)
    with_settings(:web_timeout => -1) do
      get node_path(node)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the node with the id #{node.id}")}/
  end
end
