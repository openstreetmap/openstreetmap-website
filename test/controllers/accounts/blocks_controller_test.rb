require "test_helper"

module Accounts
  class BlocksControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/account/blocks", :method => :get },
        { :controller => "accounts/blocks", :action => "index" }
      )
    end

    def test_index_not_logged_in
      get account_blocks_path
      assert_redirected_to login_path(:referer => account_blocks_path)
    end

    def test_index_not_blocked
      user = create(:user)
      session_for(user)

      get account_blocks_path
      assert_response :success
    end
  end
end
