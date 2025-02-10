require "test_helper"

module Api
  class OldRelationsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/api/0.6/relation/1/history", :method => :get },
        { :controller => "api/old_relations", :action => "index", :relation_id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/history.json", :method => :get },
        { :controller => "api/old_relations", :action => "index", :relation_id => "1", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/2", :method => :get },
        { :controller => "api/old_relations", :action => "show", :relation_id => "1", :version => "2" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/2.json", :method => :get },
        { :controller => "api/old_relations", :action => "show", :relation_id => "1", :version => "2", :format => "json" }
      )
      assert_routing(
        { :path => "/api/0.6/relation/1/2/redact", :method => :post },
        { :controller => "api/old_relations", :action => "redact", :relation_id => "1", :version => "2" }
      )
    end

    ##
    # check that a visible relations is returned properly
    def test_index
      relation = create(:relation, :with_history, :version => 2)

      get api_relation_versions_path(relation)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> relation", 2 do |dom_relations|
          assert_dom dom_relations[0], "> @id", relation.id.to_s
          assert_dom dom_relations[0], "> @version", "1"

          assert_dom dom_relations[1], "> @id", relation.id.to_s
          assert_dom dom_relations[1], "> @version", "2"
        end
      end
    end

    ##
    # check that a non-existent relations is not returned
    def test_index_invalid
      get api_relation_versions_path(0)
      assert_response :not_found
    end

    ##
    # test that redacted relations aren't visible in the history
    def test_index_redacted_unauthorised
      relation = create(:relation, :with_history, :version => 2)
      relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

      get api_relation_versions_path(relation)

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm relation[id='#{relation.id}'][version='1']", 0,
                 "redacted relation #{relation.id} version 1 shouldn't be present in the history."

      get api_relation_versions_path(relation, :show_redactions => "true")

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm relation[id='#{relation.id}'][version='1']", 0,
                 "redacted relation #{relation.id} version 1 shouldn't be present in the history when passing flag."
    end

    def test_index_redacted_normal_user
      relation = create(:relation, :with_history, :version => 2)
      relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

      get api_relation_versions_path(relation), :headers => bearer_authorization_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm relation[id='#{relation.id}'][version='1']", 0,
                 "redacted relation #{relation.id} version 1 shouldn't be present in the history, even when logged in."

      get api_relation_versions_path(relation, :show_redactions => "true"), :headers => bearer_authorization_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm relation[id='#{relation.id}'][version='1']", 0,
                 "redacted relation #{relation.id} version 1 shouldn't be present in the history, even when logged in and passing flag."
    end

    def test_index_redacted_moderator
      relation = create(:relation, :with_history, :version => 2)
      relation.old_relations.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_relation_versions_path(relation), :headers => auth_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm relation[id='#{relation.id}'][version='1']", 0,
                 "relation #{relation.id} version 1 should not be present in the history for moderators when not passing flag."

      get api_relation_versions_path(relation, :show_redactions => "true"), :headers => auth_header

      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_dom "osm relation[id='#{relation.id}'][version='1']", 1,
                 "relation #{relation.id} version 1 should still be present in the history for moderators when passing flag."
    end

    def test_show
      relation = create(:relation, :with_history, :version => 2)
      create(:old_relation_tag, :old_relation => relation.old_relations[0], :k => "k1", :v => "v1")
      create(:old_relation_tag, :old_relation => relation.old_relations[1], :k => "k2", :v => "v2")

      get api_relation_version_path(relation, 1)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> relation", 1 do
          assert_dom "> @id", relation.id.to_s
          assert_dom "> @version", "1"
          assert_dom "> tag", 1 do
            assert_dom "> @k", "k1"
            assert_dom "> @v", "v1"
          end
        end
      end

      get api_relation_version_path(relation, 2)

      assert_response :success
      assert_dom "osm:root", 1 do
        assert_dom "> relation", 1 do
          assert_dom "> @id", relation.id.to_s
          assert_dom "> @version", "2"
          assert_dom "> tag", 1 do
            assert_dom "> @k", "k2"
            assert_dom "> @v", "v2"
          end
        end
      end
    end

    ##
    # test that redacted relations aren't visible, regardless of
    # authorisation except as moderator...
    def test_show_redacted_unauthorised
      relation = create(:relation, :with_history, :version => 2)
      relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

      get api_relation_version_path(relation, 1)

      assert_response :forbidden, "Redacted relation shouldn't be visible via the version API."

      get api_relation_version_path(relation, 1, :show_redactions => "true")

      assert_response :forbidden, "Redacted relation shouldn't be visible via the version API when passing flag."
    end

    def test_show_redacted_normal_user
      relation = create(:relation, :with_history, :version => 2)
      relation.old_relations.find_by(:version => 1).redact!(create(:redaction))

      get api_relation_version_path(relation, 1), :headers => bearer_authorization_header

      assert_response :forbidden, "Redacted relation shouldn't be visible via the version API, even when logged in."

      get api_relation_version_path(relation, 1, :show_redactions => "true"), :headers => bearer_authorization_header

      assert_response :forbidden, "Redacted relation shouldn't be visible via the version API, even when logged in and passing flag."
    end

    def test_show_redacted_moderator
      relation = create(:relation, :with_history, :version => 2)
      relation.old_relations.find_by(:version => 1).redact!(create(:redaction))
      auth_header = bearer_authorization_header create(:moderator_user)

      get api_relation_version_path(relation, 1), :headers => auth_header

      assert_response :forbidden, "Redacted relation should be gone for moderator, when flag not passed."

      get api_relation_version_path(relation, 1, :show_redactions => "true"), :headers => auth_header

      assert_response :success, "Redacted relation should not be gone for moderator, when flag passed."
    end

    ##
    # test the redaction of an old version of a relation, while not being
    # authorised.
    def test_redact_relation_unauthorised
      do_redact_redactable_relation
      assert_response :unauthorized, "should need to be authenticated to redact."
    end

    ##
    # test the redaction of an old version of a relation, while being
    # authorised as a normal user.
    def test_redact_relation_normal_user
      do_redact_redactable_relation bearer_authorization_header
      assert_response :forbidden, "should need to be moderator to redact."
    end

    ##
    # test that, even as moderator, the current version of a relation
    # can't be redacted.
    def test_redact_relation_current_version
      relation = create(:relation, :with_history, :version => 4)
      redaction = create(:redaction)
      auth_header = bearer_authorization_header create(:moderator_user)

      post relation_version_redact_path(relation, 4), :params => { :redaction => redaction.id }, :headers => auth_header

      assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
    end

    def test_redact_relation_by_regular_without_write_redactions_scope
      auth_header = bearer_authorization_header(create(:user), :scopes => %w[read_prefs write_api])
      do_redact_redactable_relation(auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    def test_redact_relation_by_regular_with_write_redactions_scope
      auth_header = bearer_authorization_header(create(:user), :scopes => %w[write_redactions])
      do_redact_redactable_relation(auth_header)
      assert_response :forbidden, "should need to be moderator to redact."
    end

    def test_redact_relation_by_moderator_without_write_redactions_scope
      auth_header = bearer_authorization_header(create(:moderator_user), :scopes => %w[read_prefs write_api])
      do_redact_redactable_relation(auth_header)
      assert_response :forbidden, "should need to have write_redactions scope to redact."
    end

    def test_redact_relation_by_moderator_with_write_redactions_scope
      auth_header = bearer_authorization_header(create(:moderator_user), :scopes => %w[write_redactions])
      do_redact_redactable_relation(auth_header)
      assert_response :success, "should be OK to redact old version as moderator with write_redactions scope."
    end

    ##
    # test the redaction of an old version of a relation, while being
    # authorised as a moderator.
    def test_redact_relation_moderator
      relation = create(:relation, :with_history, :version => 4)
      relation_v3 = relation.old_relations.find_by(:version => 3)
      redaction = create(:redaction)
      auth_header = bearer_authorization_header create(:moderator_user)

      post relation_version_redact_path(*relation_v3.id), :params => { :redaction => redaction.id }, :headers => auth_header

      assert_response :success, "should be OK to redact old version as moderator."
      relation_v3.reload
      assert_predicate relation_v3, :redacted?
      assert_equal redaction, relation_v3.redaction
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
      get api_relation_version_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      assert_response :success, "After unredaction, relation should not be gone for moderator."

      # and when accessed via history
      get api_relation_versions_path(relation), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 1,
                    "relation #{relation_v1.relation_id} version #{relation_v1.version} should still be present in the history for moderators."

      auth_header = bearer_authorization_header

      # check normal user can now see the redacted data
      get api_relation_version_path(relation_v1.relation_id, relation_v1.version), :headers => auth_header
      assert_response :success, "After redaction, node should not be gone for normal user."

      # and when accessed via history
      get api_relation_versions_path(relation), :headers => auth_header
      assert_response :success, "Redaction shouldn't have stopped history working."
      assert_select "osm relation[id='#{relation_v1.relation_id}'][version='#{relation_v1.version}']", 1,
                    "relation #{relation_v1.relation_id} version #{relation_v1.version} should still be present in the history for normal users."
    end

    private

    def do_redact_redactable_relation(headers = {})
      relation = create(:relation, :with_history, :version => 4)
      redaction = create(:redaction)

      post relation_version_redact_path(relation, 3), :params => { :redaction => redaction.id }, :headers => headers
    end
  end
end
