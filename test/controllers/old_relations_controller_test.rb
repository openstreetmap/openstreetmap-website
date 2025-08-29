# frozen_string_literal: true

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

  def test_index
    relation = create(:relation, :with_history)
    sidebar_browse_check :relation_history_path, relation.id, "old_elements/index"
  end

  def test_index_show_redactions_to_unauthorized
    relation = create(:relation, :with_history)

    get relation_history_path(:id => relation, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_index_show_redactions_to_regular_user
    relation = create(:relation, :with_history)

    session_for(create(:user))
    get relation_history_path(:id => relation, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show
    relation = create(:relation, :with_history)

    get old_relation_path(relation, 1)

    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
  end

  def test_show_with_members
    relation = create(:relation, :with_history)
    create(:old_relation_member, :old_relation => relation.old_relations.first)

    get old_relation_path(relation, 1)

    assert_response :success
    assert_template "old_relations/show"
    assert_template :layout => "map"
  end

  def test_show_redacted_to_unauthorized_users
    relation = create(:relation, :with_history, :version => 2)
    relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

    get old_relation_path(relation, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_redacted_to_regular_users
    relation = create(:relation, :with_history, :version => 2)
    relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

    session_for(create(:user))
    get old_relation_path(relation, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_not_found
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
end
