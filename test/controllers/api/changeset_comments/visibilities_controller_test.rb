require "test_helper"

module Api
  module ChangesetComments
    class VisibilitiesControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/changeset_comments/1/visibility", :method => :post },
          { :controller => "api/changeset_comments/visibilities", :action => "create", :changeset_comment_id => "1" }
        )
        assert_routing(
          { :path => "/api/0.6/changeset_comments/1/visibility.json", :method => :post },
          { :controller => "api/changeset_comments/visibilities", :action => "create", :changeset_comment_id => "1", :format => "json" }
        )
        assert_routing(
          { :path => "/api/0.6/changeset_comments/1/visibility", :method => :delete },
          { :controller => "api/changeset_comments/visibilities", :action => "destroy", :changeset_comment_id => "1" }
        )
        assert_routing(
          { :path => "/api/0.6/changeset_comments/1/visibility.json", :method => :delete },
          { :controller => "api/changeset_comments/visibilities", :action => "destroy", :changeset_comment_id => "1", :format => "json" }
        )

        assert_recognizes(
          { :controller => "api/changeset_comments/visibilities", :action => "create", :changeset_comment_id => "1" },
          { :path => "/api/0.6/changeset/comment/1/unhide", :method => :post }
        )
        assert_recognizes(
          { :controller => "api/changeset_comments/visibilities", :action => "create", :changeset_comment_id => "1", :format => "json" },
          { :path => "/api/0.6/changeset/comment/1/unhide.json", :method => :post }
        )
        assert_recognizes(
          { :controller => "api/changeset_comments/visibilities", :action => "destroy", :changeset_comment_id => "1" },
          { :path => "/api/0.6/changeset/comment/1/hide", :method => :post }
        )
        assert_recognizes(
          { :controller => "api/changeset_comments/visibilities", :action => "destroy", :changeset_comment_id => "1", :format => "json" },
          { :path => "/api/0.6/changeset/comment/1/hide.json", :method => :post }
        )
      end

      def test_create_by_unauthorized
        comment = create(:changeset_comment, :visible => false)

        post api_changeset_comment_visibility_path(comment)

        assert_response :unauthorized
        assert_not comment.reload.visible
      end

      def test_create_by_normal_user
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header

        post api_changeset_comment_visibility_path(comment), :headers => auth_header

        assert_response :forbidden
        assert_not comment.reload.visible
      end

      def test_create_on_missing_comment
        auth_header = bearer_authorization_header create(:moderator_user)

        post api_changeset_comment_visibility_path(999111), :headers => auth_header

        assert_response :not_found
      end

      def test_create_without_required_scope
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[read_prefs]

        post api_changeset_comment_visibility_path(comment), :headers => auth_header

        assert_response :forbidden
        assert_not comment.reload.visible
      end

      def test_create_with_write_changeset_comments_scope
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_changeset_comments]

        post api_changeset_comment_visibility_path(comment), :headers => auth_header

        check_successful_response_xml(comment, :comment_visible => true)
      end

      def test_create_with_write_changeset_comments_scope_json
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_changeset_comments]

        post api_changeset_comment_visibility_path(comment, :format => "json"), :headers => auth_header

        check_successful_response_json(comment, :comment_visible => true)
      end

      def test_create_with_write_api_scope
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        post api_changeset_comment_visibility_path(comment), :headers => auth_header

        check_successful_response_xml(comment, :comment_visible => true)
      end

      def test_create_with_write_api_scope_json
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        post api_changeset_comment_visibility_path(comment, :format => "json"), :headers => auth_header

        check_successful_response_json(comment, :comment_visible => true)
      end

      def test_create_at_legacy_route
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        post "/api/0.6/changeset/comment/#{comment.id}/unhide", :headers => auth_header

        check_successful_response_xml(comment, :comment_visible => true)
      end

      def test_create_at_legacy_route_json
        comment = create(:changeset_comment, :visible => false)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        post "/api/0.6/changeset/comment/#{comment.id}/unhide.json", :headers => auth_header

        check_successful_response_json(comment, :comment_visible => true)
      end

      def test_destroy_by_unauthorized
        comment = create(:changeset_comment)

        delete api_changeset_comment_visibility_path(comment)

        assert_response :unauthorized
        assert comment.reload.visible
      end

      def test_destroy_by_normal_user
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header

        delete api_changeset_comment_visibility_path(comment), :headers => auth_header

        assert_response :forbidden
        assert comment.reload.visible
      end

      def test_destroy_on_missing_comment
        auth_header = bearer_authorization_header create(:moderator_user)

        delete api_changeset_comment_visibility_path(999111), :headers => auth_header

        assert_response :not_found
      end

      def test_destroy_without_required_scope
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[read_prefs]

        delete api_changeset_comment_visibility_path(comment), :headers => auth_header

        assert_response :forbidden
        assert comment.reload.visible
      end

      def test_destroy_with_write_changeset_comments_scope
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_changeset_comments]

        delete api_changeset_comment_visibility_path(comment), :headers => auth_header

        check_successful_response_xml(comment, :comment_visible => false)
      end

      def test_destroy_with_write_changeset_comments_scope_json
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_changeset_comments]

        delete api_changeset_comment_visibility_path(comment, :format => "json"), :headers => auth_header

        check_successful_response_json(comment, :comment_visible => false)
      end

      def test_destroy_with_write_api_scope
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        delete api_changeset_comment_visibility_path(comment), :headers => auth_header

        check_successful_response_xml(comment, :comment_visible => false)
      end

      def test_destroy_with_write_api_scope_json
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        delete api_changeset_comment_visibility_path(comment, :format => "json"), :headers => auth_header

        check_successful_response_json(comment, :comment_visible => false)
      end

      def test_destroy_at_legacy_route
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        post "/api/0.6/changeset/comment/#{comment.id}/hide", :headers => auth_header

        check_successful_response_xml(comment, :comment_visible => false)
      end

      def test_destroy_at_legacy_route_json
        comment = create(:changeset_comment)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_api]

        post "/api/0.6/changeset/comment/#{comment.id}/hide.json", :headers => auth_header

        check_successful_response_json(comment, :comment_visible => false)
      end

      private

      def check_successful_response_xml(comment, comment_visible:)
        assert_response :success
        assert_equal "application/xml", response.media_type
        assert_dom "osm", 1 do
          assert_dom "> changeset", 1 do
            assert_dom "> @id", comment.changeset_id.to_s
            assert_dom "> @comments_count", comment_visible ? "1" : "0"
          end
        end

        assert_equal comment_visible, comment.reload.visible
      end

      def check_successful_response_json(comment, comment_visible:)
        assert_response :success
        assert_equal "application/json", response.media_type
        js = ActiveSupport::JSON.decode(@response.body)
        assert_not_nil js["changeset"]
        assert_equal comment.changeset_id, js["changeset"]["id"]
        assert_equal comment_visible ? 1 : 0, js["changeset"]["comments_count"]

        assert_equal comment_visible, comment.reload.visible
      end
    end
  end
end
