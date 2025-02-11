require "test_helper"

module Api
  module OldWays
    class RedactionsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/way/1/2/redaction", :method => :post },
          { :controller => "api/old_ways/redactions", :action => "create", :way_id => "1", :version => "2" }
        )
        assert_routing(
          { :path => "/api/0.6/way/1/2/redaction", :method => :delete },
          { :controller => "api/old_ways/redactions", :action => "destroy", :way_id => "1", :version => "2" }
        )

        assert_recognizes(
          { :controller => "api/old_ways/redactions", :action => "create", :way_id => "1", :version => "2", :allow_delete => true },
          { :path => "/api/0.6/way/1/2/redact", :method => :post }
        )
      end

      ##
      # test that, even as moderator, the current version of a way
      # can't be redacted.
      def test_create_on_current_version
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 2)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user)

        post api_way_version_redaction_path(*old_way.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
        assert_nil old_way.reload.redaction
      end

      def test_create_without_redaction_id
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        auth_header = bearer_authorization_header create(:moderator_user)

        post api_way_version_redaction_path(*old_way.id), :headers => auth_header

        assert_response :bad_request, "should need redaction ID to redact."
        assert_nil old_way.reload.redaction
      end

      ##
      # test the redaction of an old version of a way, while not being
      # authorised.
      def test_create_by_unauthorised
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        redaction = create(:redaction)

        post api_way_version_redaction_path(*old_way.id), :params => { :redaction => redaction.id }

        assert_response :unauthorized, "should need to be authenticated to redact."
        assert_nil old_way.reload.redaction
      end

      def test_create_by_normal_user_without_write_redactions_scope
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:user), :scopes => %w[read_prefs write_api]

        post api_way_version_redaction_path(*old_way.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to be moderator to redact."
        assert_nil old_way.reload.redaction
      end

      def test_create_by_normal_user_with_write_redactions_scope
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:user), :scopes => %w[write_redactions]

        post api_way_version_redaction_path(*old_way.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to be moderator to redact."
        assert_nil old_way.reload.redaction
      end

      def test_create_by_moderator_without_write_redactions_scope
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[read_prefs write_api]

        post api_way_version_redaction_path(*old_way.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to have write_redactions scope to redact."
        assert_nil old_way.reload.redaction
      end

      def test_create_by_moderator_with_write_redactions_scope
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_redactions]

        post api_way_version_redaction_path(*old_way.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :success, "should be OK to redact old version as moderator with write_redactions scope."
        assert_equal redaction, old_way.reload.redaction
      end

      ##
      # test the unredaction of an old version of a way, while not being
      # authorised.
      def test_destroy_by_unauthorised
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        redaction = create(:redaction)
        old_way.redact!(redaction)

        delete api_way_version_redaction_path(*old_way.id)

        assert_response :unauthorized, "should need to be authenticated to unredact."
        assert_equal redaction, old_way.reload.redaction
      end

      ##
      # test the unredaction of an old version of a way, while being
      # authorised as a normal user.
      def test_destroy_by_normal_user
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        redaction = create(:redaction)
        old_way.redact!(redaction)
        auth_header = bearer_authorization_header

        delete api_way_version_redaction_path(*old_way.id), :headers => auth_header

        assert_response :forbidden, "should need to be moderator to unredact."
        assert_equal redaction, old_way.reload.redaction
      end

      ##
      # test the unredaction of an old version of a way, while being
      # authorised as a moderator.
      def test_destroy_by_moderator
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        old_way.redact!(create(:redaction))
        auth_header = bearer_authorization_header create(:moderator_user)

        delete api_way_version_redaction_path(*old_way.id), :headers => auth_header

        assert_response :success, "should be OK to unredact old version as moderator."
        assert_nil old_way.reload.redaction
      end

      def test_destroy_at_legacy_route
        way = create(:way, :with_history, :version => 2)
        old_way = way.old_ways.find_by(:version => 1)
        old_way.redact!(create(:redaction))
        auth_header = bearer_authorization_header create(:moderator_user)

        post "/api/0.6/way/#{old_way.way_id}/#{old_way.version}/redact", :headers => auth_header

        assert_response :success, "should be OK to unredact old version as moderator."
        assert_nil old_way.reload.redaction
      end
    end
  end
end
