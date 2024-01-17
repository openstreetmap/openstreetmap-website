require "test_helper"

class OldWaysControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/way/1/history/2", :method => :get },
      { :controller => "old_ways", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_visible
    way = create(:way, :with_history)
    get old_way_path(way, 1)
    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :count => 0
    end
    assert_select "a[href='#{way_version_path way, 1}']", :count => 1
  end

  def test_visible_with_shared_nodes
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

  def test_not_found
    get old_way_path(0, 0)
    assert_response :not_found
    assert_template "old_ways/not_found"
    assert_template :layout => "map"
    assert_select "#sidebar_content", /way #0 version 0 could not be found/
  end
end
