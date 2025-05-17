require "test_helper"

module Api
  module NoteVersions
    class RedactionsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/notes/1/2/redaction", :method => :post },
          { :controller => "api/note_versions/redactions", :action => "create", :note_id => "1", :version => "2" }
        )
        assert_routing(
          { :path => "/api/0.6/notes/1/2/redaction", :method => :delete },
          { :controller => "api/note_versions/redactions", :action => "destroy", :note_id => "1", :version => "2" }
        )

        assert_recognizes(
          { :controller => "api/note_versions/redactions", :action => "create", :note_id => "1", :version => "2", :allow_delete => true },
          { :path => "/api/0.6/notes/1/2/redact", :method => :post }
        )
      end

      ##
      # test that, even as moderator, the current version of a note
      # can't be redacted.
      def test_create_on_current_version
        note = create(:note_with_comments, :closed)
        note_version_to_redact = note.note_versions.last

        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user)

        post api_note_version_redaction_path(*note_version_to_redact.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
        assert_nil note_version_to_redact.reload.redaction
      end

      def test_create_without_redaction_id
        note = create(:note_with_comments, :closed)
        note_version_to_redact = note.note_versions.first

        auth_header = bearer_authorization_header create(:moderator_user)

        post api_note_version_redaction_path(*note_version_to_redact.id), :headers => auth_header

        assert_response :bad_request, "should need redaction ID to redact."
        assert_nil note_version_to_redact.reload.redaction
      end

      ##
      # test the redaction of an old version of a note, while not being
      # authorised.
      def test_create_by_unauthorised
        note = create(:note_with_comments, :closed)
        note_version_to_redact = note.note_versions.first

        redaction = create(:redaction)

        post api_note_version_redaction_path(*note_version_to_redact.id), :params => { :redaction => redaction.id }

        assert_response :unauthorized, "should need to be authenticated to redact."
        assert_nil note_version_to_redact.reload.redaction
      end

      def test_create_by_normal_user_without_write_redactions_scope
        note = create(:note_with_comments, :closed)
        note_version_to_redact = note.note_versions.first

        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:user), :scopes => %w[read_prefs write_api]

        post api_note_version_redaction_path(*note_version_to_redact.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to be moderator to redact."
        assert_nil note_version_to_redact.reload.redaction
      end

      def test_create_by_normal_user_with_write_redactions_scope
        note = create(:note_with_comments, :closed)
        note_version_to_redact = note.note_versions.first

        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:user), :scopes => %w[write_redactions]

        post api_note_version_redaction_path(*note_version_to_redact.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to be moderator to redact."
        assert_nil note_version_to_redact.reload.redaction
      end

      def test_create_by_moderator_without_write_redactions_scope
        note = create(:note_with_comments, :closed)
        note_version_to_redact = note.note_versions.first

        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[read_prefs write_api]

        post api_note_version_redaction_path(*note_version_to_redact.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to have write_redactions scope to redact."
        assert_nil note_version_to_redact.reload.redaction
      end

      def test_create_by_moderator_with_write_redactions_scope
        note = create(:note_with_comments, :closed)
        note_version_to_redact = note.note_versions.first

        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_redactions]

        post api_note_version_redaction_path(*note_version_to_redact.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :success, "should be OK to redact old version as moderator with write_redactions scope."
        assert_equal redaction, note_version_to_redact.reload.redaction
      end

      ##
      # test the unredaction of an old version of a note, while not being
      # authorised.
      def test_destroy_by_unauthorised
        note = create(:note_with_comments, :closed)
        note_version_to_unredact = note.note_versions.first

        redaction = create(:redaction)
        note_version_to_unredact.redact!(redaction)

        delete api_note_version_redaction_path(*note_version_to_unredact.id)

        assert_response :unauthorized, "should need to be authenticated to unredact."
        assert_equal redaction, note_version_to_unredact.reload.redaction
      end

      ##
      # test the unredaction of an old version of a note, while being
      # authorised as a normal user.
      def test_destroy_by_normal_user
        note = create(:note_with_comments, :closed)
        note_version_to_unredact = note.note_versions.first

        redaction = create(:redaction)
        note_version_to_unredact.redact!(redaction)
        auth_header = bearer_authorization_header

        delete api_note_version_redaction_path(*note_version_to_unredact.id), :headers => auth_header

        assert_response :forbidden, "should need to be moderator to unredact."
        assert_equal redaction, note_version_to_unredact.reload.redaction
      end

      ##
      # test the unredaction of an old version of a note, while being
      # authorised as a moderator.
      def test_destroy_by_moderator
        note = create(:note_with_comments, :closed)
        note_version_to_unredact = note.note_versions.first

        note_version_to_unredact.redact!(create(:redaction))
        auth_header = bearer_authorization_header create(:moderator_user)

        delete api_note_version_redaction_path(*note_version_to_unredact.id), :headers => auth_header

        assert_response :success, "should be OK to unredact old version as moderator."
        assert_nil note_version_to_unredact.reload.redaction
      end

      def test_destroy_at_legacy_route
        note = create(:note_with_comments, :closed)
        note_version_to_unredact = note.note_versions.first

        note_version_to_unredact.redact!(create(:redaction))
        auth_header = bearer_authorization_header create(:moderator_user)

        post "/api/0.6/notes/#{note_version_to_unredact.note_id}/#{note_version_to_unredact.version}/redact", :headers => auth_header

        assert_response :success, "should be OK to unredact old version as moderator."
        assert_nil note_version_to_unredact.reload.redaction
      end
    end
  end
end
