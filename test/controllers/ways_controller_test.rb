require "test_helper"

class WaysControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/way/1", :method => :get },
      { :controller => "ways", :action => "show", :id => "1" }
    )
  end

  def test_show
    way = create(:way)
    sidebar_browse_check :way_path, way.id, "elements/show"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :text => "1", :count => 1
    end
    assert_select ".secondary-actions a[href='#{api_way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 0
  end

  def test_show_multiple_versions
    way = create(:way, :with_history, :version => 2)
    sidebar_browse_check :way_path, way.id, "elements/show"
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 2}']", :count => 1
  end

  def test_show_relation_member
    member = create(:way)
    relation = create(:relation)
    create(:relation_member, :relation => relation, :member => member)
    sidebar_browse_check :way_path, member.id, "elements/show"
    assert_select "a[href='#{relation_path relation}']", :count => 1
  end

  def test_show_timeout
    way = create(:way)
    with_settings(:web_timeout => -1) do
      get way_path(way)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the way with the id #{way.id}")}/
  end
end
