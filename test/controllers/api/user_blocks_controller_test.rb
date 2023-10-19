require "test_helper"

module Api
  class UserBlocksControllerTest < ActionDispatch::IntegrationTest
    def test_routes
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

      get api_user_block_path(:id => block)
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

      get api_user_block_path(:id => block, :format => "json")
      assert_response :success
      js = ActiveSupport::JSON.decode(@response.body)
      assert_not_nil js
      assert_equal block.id, js["user_block"]["id"]
    end

    def test_show_not_found
      get api_user_block_path(:id => 123)
      assert_response :not_found
      assert_equal "text/plain", @response.media_type
    end
  end
end
