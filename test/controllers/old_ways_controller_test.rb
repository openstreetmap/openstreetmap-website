# frozen_string_literal: true

require "test_helper"

class OldWaysControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/way/1/history", :method => :get },
      { :controller => "old_ways", :action => "index", :id => "1" }
    )
    assert_routing(
      { :path => "/way/1/history/2", :method => :get },
      { :controller => "old_ways", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_index
    way = create(:way, :with_history)
    sidebar_browse_check :way_history_path, way.id, "old_elements/index"
  end

  def test_index_show_redactions_to_unauthorized
    way = create(:way, :with_history)

    get way_history_path(:id => way, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_index_show_redactions_to_regular_user
    way = create(:way, :with_history)

    session_for(create(:user))
    get way_history_path(:id => way, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show
    way = create(:way, :with_history)

    get old_way_path(way, 1)

    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
  end

  def test_show_with_shared_nodes
    node = create(:node, :with_history)
    way = create(:way, :with_history)
    create(:way_node, :way => way, :node => node)
    create(:old_way_node, :old_way => way.old_ways.first, :node => node)
    sharing_way = create(:way, :with_history)
    create(:way_node, :way => sharing_way, :node => node)
    create(:old_way_node, :old_way => sharing_way.old_ways.first, :node => node)

    get old_way_path(way, 1)

    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
  end

  def test_show_redacted_to_unauthorized_users
    way = create(:way, :with_history, :version => 2)
    way.old_ways.find_by(:version => 1).redact!(create(:redaction))

    get old_way_path(way, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_redacted_to_regular_users
    way = create(:way, :with_history, :version => 2)
    way.old_ways.find_by(:version => 1).redact!(create(:redaction))

    session_for(create(:user))
    get old_way_path(way, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_not_found
    get old_way_path(0, 0)

    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"
    assert_select "#sidebar_content", /way #0 version 0 could not be found/
  end

  def test_show_timeout
    way = create(:way, :with_history)

    with_settings(:web_timeout => -1) do
      get old_way_path(way, 1)
    end

    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the way with the id #{way.id}")}/
  end
end
