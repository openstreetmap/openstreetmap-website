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

  def test_history
    way = create(:way, :with_history)
    sidebar_browse_check :way_history_path, way.id, "old_elements/index"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_way_path way, 1}']", :text => "1", :count => 1
    end
  end

  def test_history_of_redacted
    way = create(:way, :with_history, :version => 4)
    way_v1 = way.old_ways.find_by(:version => 1)
    way_v1.redact!(create(:redaction))
    way_v3 = way.old_ways.find_by(:version => 3)
    way_v3.redact!(create(:redaction))

    get way_history_path(:id => way)
    assert_response :success
    assert_template "old_elements/index"

    # there are 4 revisions of the redacted way, but only 2
    # should be showing details here.
    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 2
    assert_select ".browse-section.browse-way", 2
  end

  def test_unredacted_history_of_redacted
    session_for(create(:moderator_user))
    way = create(:way, :with_history, :version => 4)
    way_v1 = way.old_ways.find_by(:version => 1)
    way_v1.redact!(create(:redaction))
    way_v3 = way.old_ways.find_by(:version => 3)
    way_v3.redact!(create(:redaction))

    get way_history_path(:id => way, :params => { :show_redactions => true })
    assert_response :success
    assert_template "old_elements/index"

    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 0
    assert_select ".browse-section.browse-way", 4
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
    assert_select ".secondary-actions a[href='#{api_way_version_path way, 1}']", :count => 1
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
    assert_select ".secondary-actions a[href='#{api_way_version_path way, 1}']", :count => 1
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
    assert_select ".secondary-actions a[href='#{api_way_version_path way, 2}']", :count => 1
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
    assert_select ".secondary-actions a[href='#{api_way_version_path way, 1}']", :count => 0
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
    assert_select ".secondary-actions a[href='#{api_way_version_path way, 1}']", :count => 0
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
    assert_select ".secondary-actions a[href='#{api_way_version_path way, 1}']", :count => 0
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

  private

  def create_redacted_way
    create(:way, :with_history, :version => 2) do |way|
      way_v1 = way.old_ways.find_by(:version => 1)
      create(:old_way_tag, :old_way => way_v1, :k => "name", :v => "TOP SECRET")
      way_v1.redact!(create(:redaction))
    end
  end
end
