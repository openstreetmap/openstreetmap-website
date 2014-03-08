require 'test_helper'
require 'old_relation_controller'

class OldRelationControllerTest < ActionController::TestCase
  api_fixtures

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
    get :history, :id => relations(:visible_relation).relation_id
    assert_response :success

    # check chat a non-existent relations is not returned
    get :history, :id => 0
    assert_response :not_found
  end

  ##
  # test the redaction of an old version of a relation, while not being
  # authorised.
  def test_redact_relation_unauthorised
    do_redact_relation(relations(:relation_with_versions_v3),
                       redactions(:example))
    assert_response :unauthorized, "should need to be authenticated to redact."
  end

    ##
  # test the redaction of an old version of a relation, while being 
  # authorised as a normal user.
  def test_redact_relation_normal_user
    basic_authorization(users(:public_user).email, "test")

    do_redact_relation(relations(:relation_with_versions_v3),
                       redactions(:example))
    assert_response :forbidden, "should need to be moderator to redact."
  end

  ##
  # test that, even as moderator, the current version of a relation
  # can't be redacted.
  def test_redact_relation_current_version
    basic_authorization(users(:moderator_user).email, "test")

    do_redact_relation(relations(:relation_with_versions_v4),
                       redactions(:example))
    assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
  end    

  ##
  # test that redacted relations aren't visible, regardless of 
  # authorisation except as moderator...
  def test_version_redacted
    relation = relations(:relation_with_redacted_versions_v2)

    get :version, :id => relation.relation_id, :version => relation.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API."

    # not even to a logged-in user
    basic_authorization(users(:public_user).email, "test")
    get :version, :id => relation.relation_id, :version => relation.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API, even when logged in."
  end

  ##
  # test that redacted nodes aren't visible in the history
  def test_history_redacted
    relation = relations(:relation_with_redacted_versions_v2)

    get :history, :id => relation.relation_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id=#{relation.relation_id}][version=#{relation.version}]", 0, "redacted relation #{relation.relation_id} version #{relation.version} shouldn't be present in the history."

    # not even to a logged-in user
    basic_authorization(users(:public_user).email, "test")
    get :version, :id => relation.relation_id, :version => relation.version
    get :history, :id => relation.relation_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id=#{relation.relation_id}][version=#{relation.version}]", 0, "redacted node #{relation.relation_id} version #{relation.version} shouldn't be present in the history, even when logged in."
  end

  ##
  # test the redaction of an old version of a relation, while being 
  # authorised as a moderator.
  def test_redact_relation_moderator
    relation = relations(:relation_with_versions_v3)
    basic_authorization(users(:moderator_user).email, "test")

    do_redact_relation(relation, redactions(:example))
    assert_response :success, "should be OK to redact old version as moderator."

    # check moderator can still see the redacted data, when passing
    # the appropriate flag
    get :version, :id => relation.relation_id, :version => relation.version
    assert_response :forbidden, "After redaction, node should be gone for moderator, when flag not passed."
    get :version, :id => relation.relation_id, :version => relation.version, :show_redactions => 'true'
    assert_response :success, "After redaction, node should not be gone for moderator, when flag passed."
    
    # and when accessed via history
    get :history, :id => relation.relation_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id=#{relation.relation_id}][version=#{relation.version}]", 0, "relation #{relation.relation_id} version #{relation.version} should not be present in the history for moderators when not passing flag."
    get :history, :id => relation.relation_id, :show_redactions => 'true'
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id=#{relation.relation_id}][version=#{relation.version}]", 1, "relation #{relation.relation_id} version #{relation.version} should still be present in the history for moderators when passing flag."
  end

  # testing that if the moderator drops auth, he can't see the
  # redacted stuff any more.
  def test_redact_relation_is_redacted
    relation = relations(:relation_with_versions_v3)
    basic_authorization(users(:moderator_user).email, "test")

    do_redact_relation(relation, redactions(:example))
    assert_response :success, "should be OK to redact old version as moderator."

    # re-auth as non-moderator
    basic_authorization(users(:public_user).email, "test")

    # check can't see the redacted data
    get :version, :id => relation.relation_id, :version => relation.version
    assert_response :forbidden, "Redacted node shouldn't be visible via the version API."
    
    # and when accessed via history
    get :history, :id => relation.relation_id
    assert_response :success, "Redaction shouldn't have stopped history working."
    assert_select "osm relation[id=#{relation.relation_id}][version=#{relation.version}]", 0, "redacted relation #{relation.relation_id} version #{relation.version} shouldn't be present in the history."
  end

  ##
  # check that the current version of a relation is equivalent to the
  # version which we're getting from the versions call.
  def check_current_version(relation_id)
    # get the current version
    current_relation = with_controller(RelationController.new) do
      get :read, :id => relation_id
      assert_response :success, "can't get current relation #{relation_id}"
      Relation.from_xml(@response.body)
    end
    assert_not_nil current_relation, "getting relation #{relation_id} returned nil"

    # get the "old" version of the relation from the version method
    get :version, :id => relation_id, :version => current_relation.version
    assert_response :success, "can't get old relation #{relation_id}, v#{current_relation.version}"
    old_relation = Relation.from_xml(@response.body)

    # check that the relations are identical
    assert_relations_are_equal current_relation, old_relation
  end

  ##
  # look at all the versions of the relation in the history and get each version from
  # the versions call. check that they're the same.
  def check_history_equals_versions(relation_id)
    get :history, :id => relation_id
    assert_response :success, "can't get relation #{relation_id} from API"
    history_doc = XML::Parser.string(@response.body).parse
    assert_not_nil history_doc, "parsing relation #{relation_id} history failed"

    history_doc.find("//osm/relation").each do |relation_doc|
      history_relation = Relation.from_xml_node(relation_doc)
      assert_not_nil history_relation, "parsing relation #{relation_id} version failed"

      get :version, :id => relation_id, :version => history_relation.version
      assert_response :success, "couldn't get relation #{relation_id}, v#{history_relation.version}"
      version_relation = Relation.from_xml(@response.body)
      assert_not_nil version_relation, "failed to parse #{relation_id}, v#{history_relation.version}"
      
      assert_relations_are_equal history_relation, version_relation
    end
  end

  def do_redact_relation(relation, redaction)
    get :version, :id => relation.relation_id, :version => relation.version
    assert_response :success, "should be able to get version #{relation.version} of node #{relation.relation_id}."
    
    # now redact it
    post :redact, :id => relation.relation_id, :version => relation.version, :redaction => redaction.id
  end
end
