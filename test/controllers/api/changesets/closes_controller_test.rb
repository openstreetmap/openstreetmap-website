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
      end

      ##
      # test that the user who opened a change can close it
      def test_update
        private_user = create(:user, :data_public => false)
        private_changeset = create(:changeset, :user => private_user)
        user = create(:user)
        changeset = create(:changeset, :user => user)

        ## Try without authentication
        put api_changeset_close_path(changeset)
        assert_response :unauthorized

        ## Try using the non-public user
        auth_header = bearer_authorization_header private_user
        put api_changeset_close_path(private_changeset), :headers => auth_header
        assert_require_public_data

        ## The try with the public user
        auth_header = bearer_authorization_header user

        cs_id = changeset.id
        put api_changeset_close_path(cs_id), :headers => auth_header
        assert_response :success

        # test that it really is closed now
        cs = Changeset.find(changeset.id)
        assert_not(cs.open?,
                   "changeset should be closed now (#{cs.closed_at} > #{Time.now.utc}.")
      end

      ##
      # test that a different user can't close another user's changeset
      def test_update_invalid
        user = create(:user)
        changeset = create(:changeset)

        auth_header = bearer_authorization_header user

        put api_changeset_close_path(changeset), :headers => auth_header
        assert_response :conflict
        assert_equal "The user doesn't own that changeset", @response.body
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

      ##
      # check that you can't close a changeset that isn't found
      def test_update_not_found
        cs_ids = [0, -132, "123"]

        # First try to do it with no auth
        cs_ids.each do |id|
          put api_changeset_close_path(id)
          assert_response :unauthorized, "Shouldn't be able close the non-existant changeset #{id}, when not authorized"
        rescue ActionController::UrlGenerationError => e
          assert_match(/No route matches/, e.to_s)
        end

        # Now try with auth
        auth_header = bearer_authorization_header
        cs_ids.each do |id|
          put api_changeset_close_path(id), :headers => auth_header
          assert_response :not_found, "The changeset #{id} doesn't exist, so can't be closed"
        rescue ActionController::UrlGenerationError => e
          assert_match(/No route matches/, e.to_s)
        end
      end
    end
  end
end
