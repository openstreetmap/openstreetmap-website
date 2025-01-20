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

    def test_index_with_unseen_block
      user = create(:user)
      session_for(user)
      unseen_block = create(:user_block, :needs_view, :user => user)

      get account_blocks_path
      assert_redirected_to user_block_path(unseen_block)
    end

    def test_index_with_two_unseen_blocks
      user = create(:user)
      session_for(user)
      unseen_block1 = create(:user_block, :needs_view, :user => user)
      unseen_block2 = create(:user_block, :needs_view, :user => user)

      get account_blocks_path
      assert_redirected_to user_block_path(unseen_block1)
      follow_redirect!

      get account_blocks_path
      assert_redirected_to user_block_path(unseen_block2)
    end
  end
end
