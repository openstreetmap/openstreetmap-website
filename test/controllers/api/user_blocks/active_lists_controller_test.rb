require "test_helper"

module Api
  module UserBlocks
    class ActiveListsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/user/blocks/active", :method => :get },
          { :controller => "api/user_blocks/active_lists", :action => "show" }
        )
        assert_routing(
          { :path => "/api/0.6/user/blocks/active.json", :method => :get },
          { :controller => "api/user_blocks/active_lists", :action => "show", :format => "json" }
        )
      end

      def test_show_no_auth_header
        get api_user_blocks_active_list_path
        assert_response :unauthorized
      end

      def test_show_no_permission
        user = create(:user)
        user_auth_header = bearer_authorization_header(user, :scopes => %w[])

        get api_user_blocks_active_list_path, :headers => user_auth_header
        assert_response :forbidden
      end

      def test_show_empty
        user = create(:user)
        user_auth_header = bearer_authorization_header(user, :scopes => %w[read_prefs])
        create(:user_block, :expired, :user => user)

        get api_user_blocks_active_list_path, :headers => user_auth_header
        assert_response :success
        assert_dom "user_block", :count => 0
      end

      def test_show
        user = create(:moderator_user)
        user_auth_header = bearer_authorization_header(user, :scopes => %w[read_prefs])
        create(:user_block, :expired, :user => user)
        block0 = create(:user_block, :user => user)
        block1 = create(:user_block, :user => user)
        create(:user_block)
        create(:user_block, :creator => user)

        get api_user_blocks_active_list_path, :headers => user_auth_header
        assert_response :success
      end

      def test_show_json
        user = create(:moderator_user)
        user_auth_header = bearer_authorization_header(user, :scopes => %w[read_prefs])
        create(:user_block, :expired, :user => user)
        block0 = create(:user_block, :user => user)
        block1 = create(:user_block, :user => user)
        create(:user_block)
        create(:user_block, :creator => user)

        get api_user_blocks_active_list_path(:format => "json"), :headers => user_auth_header
        assert_response :success
      end
    end
  end
end
