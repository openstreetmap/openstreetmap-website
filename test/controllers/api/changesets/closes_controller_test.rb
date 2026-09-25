# frozen_string_literal: true

require "test_helper"

module Api
  module Changesets
    class ClosesControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/changeset/1/close", :method => :put },
          { :controller => "api/changesets/closes", :action => "update", :changeset_id => "1" }
        )

        assert_raises(ActionController::UrlGenerationError) do
          put api_changeset_close_path(-132)
        end
      end

      def test_update_missing_changeset_when_unauthorized
        put api_changeset_close_path(999111)

        assert_response :unauthorized
      end

      def test_update_missing_changeset_by_regular_user
        auth_header = bearer_authorization_header

        put api_changeset_close_path(999111), :headers => auth_header

        assert_response :not_found
      end

      def test_update_when_unauthorized
        changeset = create(:changeset)

        put api_changeset_close_path(changeset)

        assert_response :unauthorized
        assert_predicate changeset.reload, :open?
      end

      def test_update_by_private_user
        user = create(:user, :data_public => false)
        changeset = create(:changeset, :user => user)
        auth_header = bearer_authorization_header user

        put api_changeset_close_path(changeset), :headers => auth_header

        assert_require_public_data
        assert_predicate changeset.reload, :open?
      end

      def test_update_by_changeset_non_creator
        user = create(:user)
        changeset = create(:changeset)
        auth_header = bearer_authorization_header user

        put api_changeset_close_path(changeset), :headers => auth_header

        assert_response :conflict
        assert_equal "The user doesn't own that changeset", @response.body
        assert_predicate changeset.reload, :open?
      end

      def test_update_without_required_scope
        user = create(:user)
        changeset = create(:changeset, :user => user)
        auth_header = bearer_authorization_header user, :scopes => %w[read_prefs]

        put api_changeset_close_path(changeset), :headers => auth_header

        assert_response :forbidden
        assert_predicate changeset.reload, :open?
      end

      def test_update_by_changeset_creator_with_required_scope
        user = create(:user)
        changeset = create(:changeset, :user => user)
        auth_header = bearer_authorization_header user, :scopes => %w[write_api]

        put api_changeset_close_path(changeset), :headers => auth_header

        assert_response :success
        assert_not_predicate changeset.reload, :open?
      end

      def test_update_twice
        user = create(:user)
        auth_header = bearer_authorization_header user

        freeze_time do
          changeset = create(:changeset, :user => user)

          travel 30.minutes
          put api_changeset_close_path(changeset), :headers => auth_header

          assert_response :success
          changeset.reload
          assert_not_predicate changeset, :open?
          assert_equal 0.minutes.ago, changeset.closed_at

          travel 30.minutes
          put api_changeset_close_path(changeset), :headers => auth_header

          assert_response :conflict
          changeset.reload
          assert_not_predicate changeset, :open?
          assert_equal 30.minutes.ago, changeset.closed_at
        end
      end

      ##
      # test that you can't close using another method
      def test_update_method_invalid
        user = create(:user)
        changeset = create(:changeset, :user => user)

        auth_header = bearer_authorization_header user

        get api_changeset_close_path(changeset), :headers => auth_header
        assert_response :not_found
        assert_template "rescues/routing_error"

        post api_changeset_close_path(changeset), :headers => auth_header
        assert_response :not_found
        assert_template "rescues/routing_error"
      end
    end
  end
end
