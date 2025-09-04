# frozen_string_literal: true

require "test_helper"

class OldRelationMembersControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/relation/1/history/2/members", :method => :get },
      { :controller => "old_relation_members", :action => "show", :id => "1", :version => "2" }
    )
  end

  def test_show_with_members
    relation = create(:relation, :with_history)
    create(:old_relation_member, :old_relation => relation.old_relations.first)

    get old_relation_members_path(relation, 1)

    assert_response :success
  end

  def test_show_redacted_to_unauthorized_users
    relation = create(:relation, :with_history, :version => 2)
    relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

    get old_relation_members_path(relation, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_redacted_to_regular_users
    relation = create(:relation, :with_history, :version => 2)
    relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

    session_for(create(:user))
    get old_relation_members_path(relation, 1, :params => { :show_redactions => true })

    assert_response :redirect
  end

  def test_show_not_found
    get old_relation_members_path(0, 0)

    assert_response :not_found
  end

  def test_show_timeout
    relation = create(:relation, :with_history)

    with_settings(:web_timeout => -1) do
      get old_relation_members_path(relation, 1)
    end

    assert_response :error
  end
end
