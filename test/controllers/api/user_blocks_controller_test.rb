require "test_helper"

module Api
  class UserBlocksControllerTest < ActionDispatch::IntegrationTest
    def test_routes
      assert_routing(
        { :path => "/api/0.6/user_blocks/1", :method => :get },
        { :controller => "api/user_blocks", :action => "show", :id => "1" }
      )
    end

    def test_show
      block = create(:user_block)

      get api_user_block_path(:id => block)
      assert_response :success
      assert_select "user_block[id='#{block.id}']", 1
    end

    def test_show_not_found
      get api_user_block_path(:id => 123)
      assert_response :not_found
      assert_equal "text/plain", @response.media_type
    end
  end
end
