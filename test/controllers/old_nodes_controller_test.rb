# frozen_string_literal: true

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

  def test_index
    node = create(:node, :with_history)
    sidebar_browse_check :node_history_path, node.id, "old_elements/index"
  end

  def test_index_show_redactions_to_unauthorized
    node = create(:node, :with_history)

    get node_history_path(:id => node, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_index_show_redactions_to_regular_user
    node = create(:node, :with_history)

    session_for(create(:user))
    get node_history_path(:id => node, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show
    node = create(:node, :with_history)

    get old_node_path(node, 1)

    assert_response :success
    assert_template "old_nodes/show"
    assert_template :layout => "map"
  end

  def test_show_redacted_to_unauthorized_users
    node = create(:node, :with_history, :version => 2)
    node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

    get old_node_path(node, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_redacted_to_regular_users
    node = create(:node, :with_history, :version => 2)
    node.old_nodes.find_by(:version => 1).redact!(create(:redaction))

    session_for(create(:user))
    get old_node_path(node, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_not_found
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
end
