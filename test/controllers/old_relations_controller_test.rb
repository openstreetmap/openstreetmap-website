require "test_helper"

class OldRelationsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/relation/1/history", :method => :get },
      { :controller => "old_relations", :action => "index", :id => "1" }
    )
    assert_routing(
      { :path => "/relation/1/history/2", :method => :get },
      { :controller => "old_relations", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_history
    relation = create(:relation, :with_history)
    sidebar_browse_check :relation_history_path, relation.id, "old_elements/index"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_relation_path relation, 1}']", :text => "1", :count => 1
    end
  end

  def test_history_of_redacted
    relation = create(:relation, :with_history, :version => 4)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))
    relation_v3 = relation.old_relations.find_by(:version => 3)
    relation_v3.redact!(create(:redaction))

    get relation_history_path(:id => relation)
    assert_response :success
    assert_template "old_elements/index"

    # there are 4 revisions of the redacted relation, but only 2
    # should be showing details here.
    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 2
    assert_select ".browse-section.browse-relation", 2
  end

  def test_unredacted_history_of_redacted
    session_for(create(:moderator_user))
    relation = create(:relation, :with_history, :version => 4)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))
    relation_v3 = relation.old_relations.find_by(:version => 3)
    relation_v3.redact!(create(:redaction))

    get relation_history_path(:id => relation, :params => { :show_redactions => true })
    assert_response :success
    assert_template "old_elements/index"

    assert_select ".browse-section", 4
    assert_select ".browse-section.browse-redacted", 0
    assert_select ".browse-section.browse-relation", 4
  end

  def test_visible_with_one_version
    relation = create(:relation, :with_history)
    get old_relation_path(relation, 1)
    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_relation_path relation, 1}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_relation_version_path relation, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{relation_history_path relation}']", :count => 1
  end

  def test_visible_with_two_versions
    relation = create(:relation, :with_history, :version => 2)
    get old_relation_path(relation, 1)
    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_relation_path relation, 1}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_relation_version_path relation, 1}']", :count => 1
    assert_select ".secondary-actions a[href='#{relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{relation_history_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 2}']", :count => 1

    get old_relation_path(relation, 2)
    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
    assert_select "h4", /^Version/ do
      assert_select "a[href='#{old_relation_path relation, 2}']", :count => 0
    end
    assert_select ".secondary-actions a[href='#{api_relation_version_path relation, 2}']", :count => 1
    assert_select ".secondary-actions a[href='#{relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{relation_history_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 1
  end

  def test_visible_with_members
    relation = create(:relation, :with_history)
    create(:old_relation_member, :old_relation => relation.old_relations.first)
    get old_relation_path(relation, 1)
    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
  end

  test "show unrevealed redacted versions to anonymous users" do
    relation = create_redacted_relation
    get old_relation_path(relation, 1)
    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_relation_version_path relation, 1}']", :count => 0
  end

  test "show unrevealed redacted versions to regular users" do
    session_for(create(:user))
    relation = create_redacted_relation
    get old_relation_path(relation, 1)
    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1, :params => { :show_redactions => true }}']", :count => 0
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_relation_version_path relation, 1}']", :count => 0
  end

  test "show unrevealed redacted versions to moderators" do
    session_for(create(:moderator_user))
    relation = create_redacted_relation
    get old_relation_path(relation, 1)
    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
    assert_select "td", :text => "TOP SECRET", :count => 0
    assert_select ".secondary-actions a[href='#{relation_path relation}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1, :params => { :show_redactions => true }}']", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 0
    assert_select ".secondary-actions a[href='#{api_relation_version_path relation, 1}']", :count => 0
  end

  test "don't reveal redacted versions to anonymous users" do
    relation = create_redacted_relation
    get old_relation_path(relation, 1, :params => { :show_redactions => true })
    assert_response :redirect
  end

  test "don't reveal redacted versions to regular users" do
    session_for(create(:user))
    relation = create_redacted_relation
    get old_relation_path(relation, 1, :params => { :show_redactions => true })
    assert_response :redirect
  end

  test "reveal redacted versions to moderators" do
    session_for(create(:moderator_user))
    relation = create_redacted_relation
    get old_relation_path(relation, 1, :params => { :show_redactions => true })
    assert_response :success
    assert_select "td", :text => "TOP SECRET", :count => 1
    assert_select ".secondary-actions a[href='#{old_relation_path relation, 1}']", :count => 1
  end

  def test_not_found
    get old_relation_path(0, 0)
    assert_response :not_found
    assert_template "browse/not_found"
    assert_template :layout => "map"
    assert_select "#sidebar_content", /relation #0 version 0 could not be found/
  end

  def test_show_timeout
    relation = create(:relation, :with_history)
    with_settings(:web_timeout => -1) do
      get old_relation_path(relation, 1)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the relation with the id #{relation.id}")}/
  end

  private

  def create_redacted_relation
    create(:relation, :with_history, :version => 2) do |relation|
      relation_v1 = relation.old_relations.find_by(:version => 1)
      create(:old_relation_tag, :old_relation => relation_v1, :k => "name", :v => "TOP SECRET")
      relation_v1.redact!(create(:redaction))
    end
  end
end
