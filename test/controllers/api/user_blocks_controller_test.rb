require "test_helper"

module Api
  class UserBlocksControllerTest < ActionDispatch::IntegrationTest
    def test_routes
      assert_routing(
        { :path => "/api/0.6/user_blocks", :method => :post },
        { :controller => "api/user_blocks", :action => "create" }
      )
      assert_routing(
        { :path => "/api/0.6/user_blocks/1", :method => :get },
        { :controller => "api/user_blocks", :action => "show", :id => "1" }
      )
      assert_routing(
        { :path => "/api/0.6/user_blocks/1.json", :method => :get },
        { :controller => "api/user_blocks", :action => "show", :id => "1", :format => "json" }
      )
    end

    def test_show
      blocked_user = create(:user)
      creator_user = create(:moderator_user)
      block = create(:user_block, :user => blocked_user, :creator => creator_user, :reason => "because running tests")

      get api_user_block_path(block)
      assert_response :success
      assert_select "osm>user_block", 1 do
        assert_select ">@id", block.id.to_s
        assert_select ">user", 1
        assert_select ">user>@uid", blocked_user.id.to_s
        assert_select ">creator", 1
        assert_select ">creator>@uid", creator_user.id.to_s
        assert_select ">revoker", 0
        assert_select ">reason", 1
        assert_select ">reason", "because running tests"
      end

      get api_user_block_path(block, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal block.id, js["user_block"]["id"]
    end

    def test_show_not_found
      get api_user_block_path(123)
      assert_response :not_found
      assert_equal "text/plain", @response.media_type
    end

    def test_create_no_permission
      blocked_user = create(:user)
      assert_empty blocked_user.blocks

      post api_user_blocks_path(:user => blocked_user.id, :reason => "because", :period => 1)
      assert_response :unauthorized
      assert_empty blocked_user.blocks

      regular_creator_user = create(:user)
      auth_header = bearer_authorization_header(regular_creator_user, :scopes => %w[read_prefs])
      post api_user_blocks_path(:user => blocked_user.id, :reason => "because", :period => 1), :headers => auth_header
      assert_response :forbidden
      assert_empty blocked_user.blocks

      auth_header = bearer_authorization_header(regular_creator_user, :scopes => %w[read_prefs write_blocks])
      post api_user_blocks_path(:user => blocked_user.id, :reason => "because", :period => 1), :headers => auth_header
      assert_response :forbidden
      assert_empty blocked_user.blocks

      moderator_creator_user = create(:moderator_user)
      auth_header = bearer_authorization_header(moderator_creator_user, :scopes => %w[read_prefs])
      post api_user_blocks_path(:user => blocked_user.id, :reason => "because", :period => 1), :headers => auth_header
      assert_response :forbidden
      assert_empty blocked_user.blocks
    end

    def test_create_invalid_because_no_user
      blocked_user = create(:user, :deleted)
      assert_empty blocked_user.blocks

      creator_user = create(:moderator_user)
      auth_header = bearer_authorization_header(creator_user, :scopes => %w[read_prefs write_blocks])
      post api_user_blocks_path(:reason => "because", :period => 1), :headers => auth_header
      assert_response :bad_request
      assert_equal "text/plain", @response.media_type
      assert_equal "No user was given", @response.body

      assert_empty blocked_user.blocks
    end

    def test_create_invalid_because_user_is_unknown
      creator_user = create(:moderator_user)
      auth_header = bearer_authorization_header(creator_user, :scopes => %w[read_prefs write_blocks])
      post api_user_blocks_path(:user => 0, :reason => "because", :period => 1), :headers => auth_header
      assert_response :not_found
      assert_equal "text/plain", @response.media_type
    end

    def test_create_invalid_because_user_is_deleted
      blocked_user = create(:user, :deleted)
      assert_empty blocked_user.blocks

      creator_user = create(:moderator_user)
      auth_header = bearer_authorization_header(creator_user, :scopes => %w[read_prefs write_blocks])
      post api_user_blocks_path(:user => blocked_user.id, :reason => "because", :period => 1), :headers => auth_header
      assert_response :not_found
      assert_equal "text/plain", @response.media_type

      assert_empty blocked_user.blocks
    end

    def test_create_invalid_because_missing_reason
      create_with_params_and_assert_bad_request("No reason was given", :period => "10")
    end

    def test_create_invalid_because_missing_period
      create_with_params_and_assert_bad_request("No period was given", :reason => "because")
    end

    def test_create_invalid_because_non_numeric_period
      create_with_params_and_assert_bad_request("Period should be a number of hours", :reason => "because", :period => "one hour")
    end

    def test_create_invalid_because_negative_period
      create_with_params_and_assert_bad_request("Period must be between 0 and #{UserBlock::PERIODS.max}", :reason => "go away", :period => "-1")
    end

    def test_create_invalid_because_excessive_period
      create_with_params_and_assert_bad_request("Period must be between 0 and #{UserBlock::PERIODS.max}", :reason => "go away", :period => "10000000")
    end

    def test_create_invalid_because_unknown_needs_view
      create_with_params_and_assert_bad_request("Needs_view must be true if provided", :reason => "because", :period => "1", :needs_view => "maybe")
    end

    def test_create_success
      blocked_user = create(:user)
      creator_user = create(:moderator_user)

      assert_empty blocked_user.blocks
      auth_header = bearer_authorization_header(creator_user, :scopes => %w[read_prefs write_blocks])
      post api_user_blocks_path(:user => blocked_user.id, :reason => "because", :period => 1), :headers => auth_header
      assert_response :success
      assert_equal 1, blocked_user.blocks.length

      block = blocked_user.blocks.take
      assert_predicate block, :active?
      assert_equal "because", block.reason
      assert_equal creator_user, block.creator

      assert_equal "application/xml", @response.media_type
      assert_select "osm>user_block", 1 do
        assert_select ">@id", block.id.to_s
        assert_select ">@needs_view", "false"
        assert_select ">user", 1
        assert_select ">user>@uid", blocked_user.id.to_s
        assert_select ">creator", 1
        assert_select ">creator>@uid", creator_user.id.to_s
        assert_select ">revoker", 0
        assert_select ">reason", 1
        assert_select ">reason", "because"
      end
    end

    def test_create_success_with_needs_view
      blocked_user = create(:user)
      creator_user = create(:moderator_user)

      assert_empty blocked_user.blocks
      auth_header = bearer_authorization_header(creator_user, :scopes => %w[read_prefs write_blocks])
      post api_user_blocks_path(:user => blocked_user.id, :reason => "because", :period => "1", :needs_view => "true"), :headers => auth_header
      assert_response :success
      assert_equal 1, blocked_user.blocks.length

      block = blocked_user.blocks.take
      assert_predicate block, :active?
      assert_equal "because", block.reason
      assert_equal creator_user, block.creator

      assert_equal "application/xml", @response.media_type
      assert_select "osm>user_block", 1 do
        assert_select ">@id", block.id.to_s
        assert_select ">@needs_view", "true"
        assert_select ">user", 1
        assert_select ">user>@uid", blocked_user.id.to_s
        assert_select ">creator", 1
        assert_select ">creator>@uid", creator_user.id.to_s
        assert_select ">revoker", 0
        assert_select ">reason", 1
        assert_select ">reason", "because"
      end
    end

    private

    def create_with_params_and_assert_bad_request(message, **params)
      blocked_user = create(:user)
      assert_empty blocked_user.blocks

      moderator_creator_user = create(:moderator_user)
      auth_header = bearer_authorization_header(moderator_creator_user, :scopes => %w[read_prefs write_blocks])

      post api_user_blocks_path({ :user => blocked_user.id }.merge(params)), :headers => auth_header
      assert_response :bad_request
      assert_equal "text/plain", @response.media_type
      assert_equal message, @response.body

      assert_empty blocked_user.blocks
    end
  end
end
