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

  def test_show_map_geometry
    way = create(:way, :with_history, :version => 2)
    old_way = way.old_ways.find_by!(:version => 1)
    first, second = create_list(:node, 2)
    [second, first, second].each_with_index do |node, i|
      create(:old_way_node, :old_way => old_way, :node => node, :sequence_id => i + 1)
    end
    create(:old_node, :current_node => first, :timestamp => old_way.timestamp, :lat => 51, :lon => -2)
    create(:old_node, :current_node => first, :version => 2, :timestamp => old_way.timestamp + 1.second, :lat => 54, :lon => -3)
    create(:old_node, :current_node => second, :timestamp => old_way.timestamp - 1.day, :lat => 50, :lon => -1)
    create(:old_way_tag, :old_way => old_way, :k => "building", :v => "yes")

    get old_way_path(way, 1, :format => :json)

    assert_response :success
    assert_equal [
      { "type" => "node", "id" => first.id, "lat" => 51, "lon" => -2 },
      { "type" => "node", "id" => second.id, "lat" => 50, "lon" => -1 },
      { "type" => "way", "id" => way.id, "nodes" => [second.id, first.id, second.id], "tags" => { "building" => "yes" } }
    ], response.parsed_body.fetch("elements")
  end

  def test_show_map_geometry_with_unavailable_node
    way = create(:way, :with_history)
    old_way = way.old_ways.first
    node = create(:node)
    create(:old_way_node, :old_way => old_way, :node => node)

    get old_way_path(way, 1, :format => :json)
    assert_empty response.parsed_body.fetch("elements")

    create(:old_node, :current_node => node, :timestamp => old_way.timestamp - 1.day)
    historical_node = create(:old_node, :current_node => node, :version => 2, :timestamp => old_way.timestamp, :visible => false)

    get old_way_path(way, 1, :format => :json)
    assert_empty response.parsed_body.fetch("elements")

    historical_node.update!(:visible => true, :redaction => create(:redaction))

    get old_way_path(way, 1, :format => :json)
    assert_empty response.parsed_body.fetch("elements")
  end

  def test_show_map_geometry_with_unavailable_way
    way = create(:way, :with_history)
    old_way = way.old_ways.first
    node = create(:node)
    create(:old_node, :current_node => node, :timestamp => old_way.timestamp)
    create(:old_way_node, :old_way => old_way, :node => node)
    old_way.update!(:visible => false)

    get old_way_path(way, 1, :format => :json)
    assert_empty response.parsed_body.fetch("elements")

    old_way.update!(:visible => true, :redaction => create(:redaction))

    get old_way_path(way, 1, :format => :json)
    assert_empty response.parsed_body.fetch("elements")
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
