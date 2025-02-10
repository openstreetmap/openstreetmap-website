require "test_helper"

class OldNodesControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/node/1/history", :method => :get },
      { :controller => "old_nodes", :action => "index", :id => "1" }
    )
    assert_routing(
      { :path => "/node/1/history/2", :method => :get },
      { :controller => "old_nodes", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_history
    node = create(:node, :with_history)
    sidebar_browse_check :node_history_path, node.id, "old_elements/index"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_node_path node, 1}']", :text => "1", :count => 1
    end
  end

  def test_history_of_redacted
    node = create(:node, :with_history, :deleted, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v1.redact!(create(:redaction))

    get node_history_path(:id => node)
    assert_response :success
    assert_template "old_elements/index"

    # there are 2 revisions of the redacted node, but only one
    # should be showing details here.
    assert_select ".browse-section", 2
    assert_select ".browse-section.browse-redacted", 1
    assert_select ".browse-section.browse-node", 1
    assert_select ".browse-section.browse-node .latitude", 0
    assert_select ".browse-section.browse-node .longitude", 0
  end

  def test_unredacted_history_of_redacted
    session_for(create(:moderator_user))
    node = create(:node, :with_history, :deleted, :version => 2)
    node_v1 = node.old_nodes.find_by(:version => 1)
    node_v1.redact!(create(:redaction))

    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :success
    assert_template "old_elements/index"

    assert_select ".browse-section", 2
    assert_select ".browse-section.browse-redacted", 0
    assert_select ".browse-section.browse-node", 2
  end

  def test_anonymous_user_history_page_secondary_actions
    node = create(:node, :with_history)
    get node_history_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 0
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_regular_user_history_page_secondary_actions
    session_for(create(:user))
    node = create(:node, :with_history)
    get node_history_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 0
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
  end

  def test_moderator_user_history_page_secondary_actions
    session_for(create(:moderator_user))
    node = create(:node, :with_history)
    get node_history_path(:id => node)
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 0
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 1
  end

  def test_anonymous_user_unredacted_history_page_secondary_actions
    node = create(:node, :with_history)
    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :redirect
  end

  def test_regular_user_unredacted_history_page_secondary_actions
    session_for(create(:user))
    node = create(:node, :with_history)
    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :redirect
  end

  def test_moderator_user_unredacted_history_page_secondary_actions
    session_for(create(:moderator_user))
    node = create(:node, :with_history)
    get node_history_path(:id => node, :params => { :show_redactions => true })
    assert_response :success
    assert_select ".secondary-actions a", :text => "View Details", :count => 1
    assert_select ".secondary-actions a", :text => "View History", :count => 1
    assert_select ".secondary-actions a", :text => "View Unredacted History", :count => 0
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
    assert_select ".secondary-actions a[href='#{api_node_version_path node, 1}']", :count => 1
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
    assert_select ".secondary-actions a[href='#{api_node_version_path node, 1}']", :count => 1
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
    assert_select ".secondary-actions a[href='#{api_node_version_path node, 2}']", :count => 1
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
    assert_select ".secondary-actions a[href='#{api_node_version_path node, 1}']", :count => 0
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
    assert_select ".secondary-actions a[href='#{api_node_version_path node, 1}']", :count => 0
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
    assert_select ".secondary-actions a[href='#{api_node_version_path node, 1}']", :count => 0
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
    assert_template "browse/not_found"
    assert_template :layout => "map"
    assert_select "#sidebar_content", /node #0 version 0 could not be found/
  end

  def test_show_timeout
    node = create(:node, :with_history)
    with_settings(:web_timeout => -1) do
      get old_node_path(node, 1)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the node with the id #{node.id}")}/
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
