require "test_helper"

module Api
  class OldRelationsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/relation/1/history", :method => :get },
        { :controller => "api/old_relations", :action => "history", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/2", :method => :get },
        { :controller => "api/old_relations", :action => "show", :id => "1", :version => "2" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/history.json", :method => :get },
        { :controller => "api/old_relations", :action => "history", :id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/2.json", :method => :get },
        { :controller => "api/old_relations", :action => "show", :id => "1", :version => "2", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/2/redact", :method => :post },
        { :controller => "api/old_relations", :action => "redact", :id => "1", :version => "2" }
      )
    end

    # -------------------------------------
    # Test reading old relations.
    # -------------------------------------
    def test_history
      # check that a visible relations is returned properly
      get api_relation_history_path(create(:relation, :with_history))
      assert_response :success

      # check chat a non-existent relations is not returned
      get api_relation_history_path(0)
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

      auth_header = bearer_authorization_header

      do_redact_relation(relation_v3, create(:redaction), auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    ##
    # test that, even as moderator, the current version of a relation
    # can't be redacted.
    def test_redact_relation_current_version
      relation = create(:relation, :with_history, :version => 4)
      relation_latest = relation.old_relations.last

      auth_header = bearer_authorization_header create(:moderator_user)

      do_redact_relation(relation_latest, create(:redaction), auth_header)
      assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
    end

    def test_redact_relation_by_regular_with_read_prefs_scope
      auth_header = create_bearer_auth_header(create(:user), %w[read_prefs])
      do_redact_redactable_relation(auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    def test_redact_relation_by_regular_with_write_api_scope
      auth_header = create_bearer_auth_header(create(:user), %w[write_api])
      do_redact_redactable_relation(auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    def test_redact_relation_by_regular_with_write_redactions_scope
      auth_header = create_bearer_auth_header(create(:user), %w[write_redactions])
      do_redact_redactable_relation(auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    def test_redact_relation_by_moderator_with_read_prefs_scope
      auth_header = create_bearer_auth_header(create(:moderator_user), %w[read_prefs])
      do_redact_redactable_relation(auth_header)
      assert_response :forbidden, "should need to have write_redactions scope to redact."
    end

    def test_redact_relation_by_moderator_with_write_api_scope
      auth_header = create_bearer_auth_header(create(:moderator_user), %w[write_api])
      do_redact_redactable_relation(auth_header)
      assert_response :success, "should be OK to redact old version as moderator with write_api scope."
      # assert_response :forbidden, "should need to have write_redactions scope to redact."
    end

    def test_redact_relation_by_moderator_with_write_redactions_scope
      auth_header = create_bearer_auth_header(create(:moderator_user), %w[write_redactions])
      do_redact_redactable_relation(auth_header)
      assert_response :success, "should be OK to redact old version as moderator with write_redactions scope."
    end

    ##
    # test that redacted relations aren't visible, regardless of
    # authorisation except as moderator...
    def test_version_redacted
      relation = create(:relation, :with_history, :version => 2)
      relation_v1 = relation.old_relations.find_by(:version => 1)
      relation_v1.redact!(create(:redaction))

      get api_old_relation_path(relation_v1.relation_id, relation_v1.version)
      assert_response :forbidden, "Redacted relation shouldn't be visible via the version API."

      # not even to a logged-in user
      auth_header = bearer_authorization_header
      get api_old_relation_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      assert_response :forbidden, "Redacted relation shouldn't be visible via the version API, even when logged in."
    end

    ##
    # test that redacted relations aren't visible in the history
    def test_history_redacted
      relation = create(:relation, :with_history, :version => 2)
      relation_v1 = relation.old_relations.find_by(:version => 1)
      relation_v1.redact!(create(:redaction))

      get api_relation_history_path(relation)
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 0,
                    "redacted relation #{relation_v1.relation_id} version #{relation_v1.version} shouldn't be present in the history."

      # not even to a logged-in user
      auth_header = bearer_authorization_header
      get api_old_relation_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      get api_relation_history_path(relation), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 0,
                    "redacted relation #{relation_v1.relation_id} version #{relation_v1.version} shouldn't be present in the history, even when logged in."
    end

    ##
    # test the redaction of an old version of a relation, while being
    # authorised as a moderator.
    def test_redact_relation_moderator
      relation = create(:relation, :with_history, :version => 4)
      relation_v3 = relation.old_relations.find_by(:version => 3)

      auth_header = bearer_authorization_header create(:moderator_user)

      do_redact_relation(relation_v3, create(:redaction), auth_header)
      assert_response :success, "should be OK to redact old version as moderator."

      # check moderator can still see the redacted data, when passing
      # the appropriate flag
      get api_old_relation_path(relation_v3.relation_id, relation_v3.version), :headers => auth_header
      assert_response :forbidden, "After redaction, relation should be gone for moderator, when flag not passed."
      get api_old_relation_path(relation_v3.relation_id, relation_v3.version, :show_redactions => "true"), :headers => auth_header
      assert_response :success, "After redaction, relation should not be gone for moderator, when flag passed."

      # and when accessed via history
      get api_relation_history_path(relation), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v3.relation_id}'][version='#{relation_v3.version}']", 0,
                    "relation #{relation_v3.relation_id} version #{relation_v3.version} should not be present in the history for moderators when not passing flag."
      get api_relation_history_path(relation, :show_redactions => "true"), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v3.relation_id}'][version='#{relation_v3.version}']", 1,
                    "relation #{relation_v3.relation_id} version #{relation_v3.version} should still be present in the history for moderators when passing flag."
    end

    # testing that if the moderator drops auth, he can't see the
    # redacted stuff any more.
    def test_redact_relation_is_redacted
      relation = create(:relation, :with_history, :version => 4)
      relation_v3 = relation.old_relations.find_by(:version => 3)

      auth_header = bearer_authorization_header create(:moderator_user)

      do_redact_relation(relation_v3, create(:redaction), auth_header)
      assert_response :success, "should be OK to redact old version as moderator."

      # re-auth as non-moderator
      auth_header = bearer_authorization_header

      # check can't see the redacted data
      get api_old_relation_path(relation_v3.relation_id, relation_v3.version), :headers => auth_header
      assert_response :forbidden, "Redacted relation shouldn't be visible via the version API."

      # and when accessed via history
      get api_relation_history_path(relation), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v3.relation_id}'][version='#{relation_v3.version}']", 0,
                    "redacted relation #{relation_v3.relation_id} version #{relation_v3.version} shouldn't be present in the history."
    end

    ##
    # test the unredaction of an old version of a relation, while not being
    # authorised.
    def test_unredact_relation_unauthorised
      relation = create(:relation, :with_history, :version => 2)
      relation_v1 = relation.old_relations.find_by(:version => 1)
      relation_v1.redact!(create(:redaction))

      post relation_version_redact_path(relation_v1.relation_id, relation_v1.version)
      assert_response :unauthorized, "should need to be authenticated to unredact."
    end

    ##
    # test the unredaction of an old version of a relation, while being
    # authorised as a normal user.
    def test_unredact_relation_normal_user
      relation = create(:relation, :with_history, :version => 2)
      relation_v1 = relation.old_relations.find_by(:version => 1)
      relation_v1.redact!(create(:redaction))

      auth_header = bearer_authorization_header

      post relation_version_redact_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      assert_response :forbidden, "should need to be moderator to unredact."
    end

    ##
    # test the unredaction of an old version of a relation, while being
    # authorised as a moderator.
    def test_unredact_relation_moderator
      relation = create(:relation, :with_history, :version => 2)
      relation_v1 = relation.old_relations.find_by(:version => 1)
      relation_v1.redact!(create(:redaction))

      auth_header = bearer_authorization_header create(:moderator_user)

      post relation_version_redact_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      assert_response :success, "should be OK to unredact old version as moderator."

      # check moderator can still see the redacted data, without passing
      # the appropriate flag
      get api_old_relation_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      assert_response :success, "After unredaction, relation should not be gone for moderator."

      # and when accessed via history
      get api_relation_history_path(relation), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 1,
                    "relation #{relation_v1.relation_id} version #{relation_v1.version} should still be present in the history for moderators."

      auth_header = bearer_authorization_header

      # check normal user can now see the redacted data
      get api_old_relation_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      assert_response :success, "After redaction, node should not be gone for normal user."

      # and when accessed via history
      get api_relation_history_path(relation), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 1,
                    "relation #{relation_v1.relation_id} version #{relation_v1.version} should still be present in the history for normal users."
    end

    private

    ##
    # check that the current version of a relation is equivalent to the
    # version which we're getting from the versions call.
    def check_current_version(relation_id)
      # get the current version
      current_relation = with_controller(RelationsController.new) do
        get :show, :params => { :id => relation_id }
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

    def create_bearer_auth_header(user, scopes)
      token = create(:oauth_access_token,
                     :resource_owner_id => user.id,
                     :scopes => scopes)
      bearer_authorization_header(token)
    end

    def do_redact_redactable_relation(headers = {})
      relation = create(:relation, :with_history, :version => 4)
      relation_v3 = relation.old_relations.find_by(:version => 3)
      do_redact_relation(relation_v3, create(:redaction), headers)
    end

    def do_redact_relation(relation, redaction, headers = {})
      get api_old_relation_path(relation.relation_id, relation.version)
      assert_response :success, "should be able to get version #{relation.version} of relation #{relation.relation_id}."

      # now redact it
      post relation_version_redact_path(relation.relation_id, relation.version), :params => { :redaction => redaction.id }, :headers => headers
    end
  end
end
