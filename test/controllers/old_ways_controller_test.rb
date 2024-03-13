require "test_helper"

class OldWaysControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/way/1/history/2", :method => :get },
      { :controller => "old_ways", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_visible_with_one_version
    way = create(:way, :with_history)
    get old_way_path(way, 1)
    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_old_way_path way, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
  end

  def test_visible_with_two_versions
    way = create(:way, :with_history, :version => 2)
    get old_way_path(way, 1)
    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_old_way_path way, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 2}']", :count => 1

    get old_way_path(way, 2)
    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 2}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_old_way_path way, 2}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{way_history_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 1
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

  test "show unrevealed redacted versions to anonymous users" do
    way = create_redacted_way
    get old_way_path(way, 1)
    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_old_way_path way, 1}']", :count => 0
  end

  test "show unrevealed redacted versions to regular users" do
    session_for(create(:user))
    way = create_redacted_way
    get old_way_path(way, 1)
    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_old_way_path way, 1}']", :count => 0
  end

  test "show unrevealed redacted versions to moderators" do
    session_for(create(:moderator_user))
    way = create_redacted_way
    get old_way_path(way, 1)
    assert_response :success
    assert_template "old_ways/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{way_path way}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1, :params => { :show_redactions => true }}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_old_way_path way, 1}']", :count => 0
  end

  test "don't reveal redacted versions to anonymous users" do
    way = create_redacted_way
    get old_way_path(way, 1, :params => { :show_redactions => true })
    assert_response :redirect
  end

  test "don't reveal redacted versions to regular users" do
    session_for(create(:user))
    way = create_redacted_way
    get old_way_path(way, 1, :params => { :show_redactions => true })
    assert_response :redirect
  end

  test "reveal redacted versions to moderators" do
    session_for(create(:moderator_user))
    way = create_redacted_way
    get old_way_path(way, 1, :params => { :show_redactions => true })
    assert_response :success
    assert_select "td", :text => "TOP SECRET", :count => 1
    assert_select ".secondary-actions a[href='#{old_way_path way, 1}']", :count => 1
  end

  def test_not_found
    get old_way_path(0, 0)
    assert_response :not_found
    assert_template "old_ways/not_found"
    assert_template :layout => "map"
    assert_select "#sidebar_content", /way #0 version 0 could not be found/
  end

  private

  def create_redacted_way
    create(:way, :with_history, :version => 2) do |way|
      way_v1 = way.old_ways.find_by(:version => 1)
      create(:old_way_tag, :old_way => way_v1, :k => "name", :v => "TOP SECRET")
      way_v1.redact!(create(:redaction))
    end
  end
end
