require "test_helper"
require "old_relation_controller"

class OldRelationControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/relation/1/history", :method => :get },
      { :controller => "old_relation", :action => "history", :id => "1" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1/2", :method => :get },
      { :controller => "old_relation", :action => "version", :id => "1", :version => "2" }
    )
    assert_routing(
      { :path => "/api/0.6/relation/1/2/redact", :method => :post },
      { :controller => "old_relation", :action => "redact", :id => "1", :version => "2" }
    )
  end

  # -------------------------------------
  # Test reading old relations.
  # -------------------------------------
  def test_history
    # check that a visible relations is returned properly
    get :history, :params => { :id => create(:relation, :with_history).id }
    assert_response :success

    # check chat a non-existent relations is not returned
    get :history, :params => { :id => 0 }
    assert_response :not_found
  end

  ##
  # test the redaction of an old version of a relation, while not being
  # authorised.
  def test_redact_relation_unauthorised
    relation = create(:relation, :with_history, :version => 4)
    relation_v3 = relation.old_relations.find_by(:version => 3)

    do_redact_relation(relation_v3, create(:redaction))
    assert_response :unauthorized, "should need to be authenticated to redact."
  end

  ##
  # test the redaction of an old version of a relation, while being
  # authorised as a normal user.
  def test_redact_relation_normal_user
    relation = create(:relation, :with_history, :version => 4)
    relation_v3 = relation.old_relations.find_by(:version => 3)

    basic_authorization(create(:user).email, "test")

    do_redact_relation(relation_v3, create(:redaction))
    assert_response :forbidden, "should need to be moderator to redact."
  end

  ##
  # test that, even as moderator, the current version of a relation
  # can't be redacted.
  def test_redact_relation_current_version
    relation = create(:relation, :with_history, :version => 4)
    relation_latest = relation.old_relations.last

    basic_authorization(create(:moderator_user).email, "test")

    do_redact_relation(relation_latest, create(:redaction))
    assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
  end

  ##
  # test that redacted relations aren't visible, regardless of
  # authorisation except as moderator...
  def test_version_redacted
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))

    get :version, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    assert_response :forbidden, "Redacted relation shouldn't be visible via the version API."

    # not even to a logged-in user
    basic_authorization(create(:user).email, "test")
    get :version, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    assert_response :forbidden, "Redacted relation shouldn't be visible via the version API, even when logged in."
  end

  ##
  # test that redacted relations aren't visible in the history
  def test_history_redacted
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))

    get :history, :params => { :id => relation_v1.relation_id }
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 0, "redacted relation #{relation_v1.relation_id} version #{relation_v1.version} shouldn't be present in the history."

    # not even to a logged-in user
    basic_authorization(create(:user).email, "test")
    get :version, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    get :history, :params => { :id => relation_v1.relation_id }
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 0, "redacted relation #{relation_v1.relation_id} version #{relation_v1.version} shouldn't be present in the history, even when logged in."
  end

  ##
  # test the redaction of an old version of a relation, while being
  # authorised as a moderator.
  def test_redact_relation_moderator
    relation = create(:relation, :with_history, :version => 4)
    relation_v3 = relation.old_relations.find_by(:version => 3)

    basic_authorization(create(:moderator_user).email, "test")

    do_redact_relation(relation_v3, create(:redaction))
    assert_response :success, "should be OK to redact old version as moderator."

    # check moderator can still see the redacted data, when passing
    # the appropriate flag
    get :version, :params => { :id => relation_v3.relation_id, :version => relation_v3.version }
    assert_response :forbidden, "After redaction, relation should be gone for moderator, when flag not passed."
    get :version, :params => { :id => relation_v3.relation_id, :version => relation_v3.version, :show_redactions => "true" }
    assert_response :success, "After redaction, relation should not be gone for moderator, when flag passed."

    # and when accessed via history
    get :history, :params => { :id => relation_v3.relation_id }
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id='#{relation_v3.relation_id}'][version='#{relation_v3.version}']", 0, "relation #{relation_v3.relation_id} version #{relation_v3.version} should not be present in the history for moderators when not passing flag."
    get :history, :params => { :id => relation_v3.relation_id, :show_redactions => "true" }
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id='#{relation_v3.relation_id}'][version='#{relation_v3.version}']", 1, "relation #{relation_v3.relation_id} version #{relation_v3.version} should still be present in the history for moderators when passing flag."
  end

  # testing that if the moderator drops auth, he can't see the
  # redacted stuff any more.
  def test_redact_relation_is_redacted
    relation = create(:relation, :with_history, :version => 4)
    relation_v3 = relation.old_relations.find_by(:version => 3)

    basic_authorization(create(:moderator_user).email, "test")

    do_redact_relation(relation_v3, create(:redaction))
    assert_response :success, "should be OK to redact old version as moderator."

    # re-auth as non-moderator
    basic_authorization(create(:user).email, "test")

    # check can't see the redacted data
    get :version, :params => { :id => relation_v3.relation_id, :version => relation_v3.version }
    assert_response :forbidden, "Redacted relation shouldn't be visible via the version API."

    # and when accessed via history
    get :history, :params => { :id => relation_v3.relation_id }
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id='#{relation_v3.relation_id}'][version='#{relation_v3.version}']", 0, "redacted relation #{relation_v3.relation_id} version #{relation_v3.version} shouldn't be present in the history."
  end

  ##
  # test the unredaction of an old version of a relation, while not being
  # authorised.
  def test_unredact_relation_unauthorised
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))

    post :redact, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    assert_response :unauthorized, "should need to be authenticated to unredact."
  end

  ##
  # test the unredaction of an old version of a relation, while being
  # authorised as a normal user.
  def test_unredact_relation_normal_user
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))

    basic_authorization(create(:user).email, "test")

    post :redact, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    assert_response :forbidden, "should need to be moderator to unredact."
  end

  ##
  # test the unredaction of an old version of a relation, while being
  # authorised as a moderator.
  def test_unredact_relation_moderator
    relation = create(:relation, :with_history, :version => 2)
    relation_v1 = relation.old_relations.find_by(:version => 1)
    relation_v1.redact!(create(:redaction))

    basic_authorization(create(:moderator_user).email, "test")

    post :redact, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    assert_response :success, "should be OK to unredact old version as moderator."

    # check moderator can still see the redacted data, without passing
    # the appropriate flag
    get :version, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    assert_response :success, "After unredaction, relation should not be gone for moderator."

    # and when accessed via history
    get :history, :params => { :id => relation_v1.relation_id }
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 1, "relation #{relation_v1.relation_id} version #{relation_v1.version} should still be present in the history for moderators."

    basic_authorization(create(:user).email, "test")

    # check normal user can now see the redacted data
    get :version, :params => { :id => relation_v1.relation_id, :version => relation_v1.version }
    assert_response :success, "After redaction, node should not be gone for normal user."

    # and when accessed via history
    get :history, :params => { :id => relation_v1.relation_id }
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 1, "relation #{relation_v1.relation_id} version #{relation_v1.version} should still be present in the history for normal users."
  end

  private

  ##
  # check that the current version of a relation is equivalent to the
  # version which we're getting from the versions call.
  def check_current_version(relation_id)
    # get the current version
    current_relation = with_controller(RelationController.new) do
      get :read, :params => { :id => relation_id }
      assert_response :success, "can't get current relation #{relation_id}"
      Relation.from_xml(@response.body)
    end
    assert_not_nil current_relation, "getting relation #{relation_id} returned nil"

    # get the "old" version of the relation from the version method
    get :version, :params => { :id => relation_id, :version => current_relation.version }
    assert_response :success, "can't get old relation #{relation_id}, v#{current_relation.version}"
    old_relation = Relation.from_xml(@response.body)

    # check that the relations are identical
    assert_relations_are_equal current_relation, old_relation
  end

  ##
  # look at all the versions of the relation in the history and get each version from
  # the versions call. check that they're the same.
  def check_history_equals_versions(relation_id)
    get :history, :params => { :id => relation_id }
    assert_response :success, "can't get relation #{relation_id} from API"
    history_doc = XML::Parser.string(@response.body).parse
    assert_not_nil history_doc, "parsing relation #{relation_id} history failed"

    history_doc.find("//osm/relation").each do |relation_doc|
      history_relation = Relation.from_xml_node(relation_doc)
      assert_not_nil history_relation, "parsing relation #{relation_id} version failed"

      get :version, :params => { :id => relation_id, :version => history_relation.version }
      assert_response :success, "couldn't get relation #{relation_id}, v#{history_relation.version}"
      version_relation = Relation.from_xml(@response.body)
      assert_not_nil version_relation, "failed to parse #{relation_id}, v#{history_relation.version}"

      assert_relations_are_equal history_relation, version_relation
    end
  end

  def do_redact_relation(relation, redaction)
    get :version, :params => { :id => relation.relation_id, :version => relation.version }
    assert_response :success, "should be able to get version #{relation.version} of relation #{relation.relation_id}."

    # now redact it
    post :redact, :params => { :id => relation.relation_id, :version => relation.version, :redaction => redaction.id }
  end
end
