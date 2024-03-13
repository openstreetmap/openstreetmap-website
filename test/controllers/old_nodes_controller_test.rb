require "test_helper"

class OldNodesControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/node/1/history/2", :method => :get },
      { :controller => "old_nodes", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_visible_with_one_version
    node = create(:node, :with_history)
    get old_node_path(node, 1)
    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_old_node_path node, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{node_history_path node}']", :count => 1
  end

  def test_visible_with_two_versions
    node = create(:node, :with_history, :version => 2)
    get old_node_path(node, 1)
    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_old_node_path node, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{node_history_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 2}']", :count => 1

    get old_node_path(node, 2)
    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 2}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_old_node_path node, 2}']", :count => 1
    assert_select ".secondary-actions a[href='#{node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{node_history_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 1
  end

  test "show unrevealed redacted versions to anonymous users" do
    node = create_redacted_node
    get old_node_path(node, 1)
    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_old_node_path node, 1}']", :count => 0
  end

  test "show unrevealed redacted versions to regular users" do
    session_for(create(:user))
    node = create_redacted_node
    get old_node_path(node, 1)
    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_old_node_path node, 1}']", :count => 0
  end

  test "show unrevealed redacted versions to moderators" do
    session_for(create(:moderator_user))
    node = create_redacted_node
    get old_node_path(node, 1)
    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{node_path node}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1, :params => { :show_redactions => true }}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_old_node_path node, 1}']", :count => 0
  end

  test "don't reveal redacted versions to anonymous users" do
    node = create_redacted_node
    get old_node_path(node, 1, :params => { :show_redactions => true })
    assert_response :redirect
  end

  test "don't reveal redacted versions to regular users" do
    session_for(create(:user))
    node = create_redacted_node
    get old_node_path(node, 1, :params => { :show_redactions => true })
    assert_response :redirect
  end

  test "reveal redacted versions to moderators" do
    session_for(create(:moderator_user))
    node = create_redacted_node
    get old_node_path(node, 1, :params => { :show_redactions => true })
    assert_response :success
    assert_select "td", :text => "TOP SECRET", :count => 1
    assert_select ".secondary-actions a[href='#{old_node_path node, 1}']", :count => 1
  end

  def test_not_found
    get old_node_path(0, 0)
    assert_response :not_found
    assert_template "old_nodes/not_found"
    assert_template :layout => "map"
    assert_select "#sidebar_content", /node #0 version 0 could not be found/
  end

  private

  def create_redacted_node
    create(:node, :with_history, :version => 2) do |node|
      node_v1 = node.old_nodes.find_by(:version => 1)
      create(:old_node_tag, :old_node => node_v1, :k => "name", :v => "TOP SECRET")
      node_v1.redact!(create(:redaction))
    end
  end
end
