require "test_helper"

class RelationsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/relation/1", :method => :get },
      { :controller => "relations", :action => "show", :id => "1" }
    )
  end

  def test_show
    relation = create(:relation)
    sidebar_browse_check :relation_path, relation.id, "elements/show"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_relation_path relation, 1}']", :text => "1", :count => 1
    end
    assert_select ".secondary-actions a[href='#{api_relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{relation_history_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 0
  end

  def test_show_multiple_versions
    relation = create(:relation, :with_history, :version => 2)
    sidebar_browse_check :relation_path, relation.id, "elements/show"
    assert_select ".secondary-actions a[href='#{relation_history_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 2}']", :count => 1
  end

  def test_show_relation_member
    member = create(:relation)
    relation = create(:relation)
    create(:relation_member, :relation => relation, :member => member)
    sidebar_browse_check :relation_path, member.id, "elements/show"
    assert_select "a[href='#{relation_path relation}']", :count => 1
  end

  def test_show_timeout
    relation = create(:relation)
    with_settings(:web_timeout => -1) do
      get relation_path(relation)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the relation with the id #{relation.id}")}/
  end
end
