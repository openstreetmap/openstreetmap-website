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
      assert_dom "#content > .content-body" do
        assert_dom "p", :text => /no active blocks/
      end
    end

    def test_index_with_inactive_block
      user = create(:user)
      session_for(user)
      create(:user_block, :expired, :user => user)

      get account_blocks_path
      assert_response :success
      assert_dom "#content > .content-body" do
        assert_dom "p", :text => /no active blocks/
      end
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

    def test_index_with_seen_block
      user = create(:user)
      session_for(user)
      seen_block = create(:user_block, :user => user)

      get account_blocks_path
      assert_redirected_to user_block_path(seen_block)
    end

    def test_index_with_seen_and_unseen_blocks
      user = create(:user)
      session_for(user)
      seen_block = create(:user_block, :user => user)
      unseen_block = create(:user_block, :needs_view, :user => user)

      get account_blocks_path
      assert_redirected_to user_block_path(unseen_block)
      follow_redirect!

      get account_blocks_path
      assert_redirected_to user_block_path(seen_block)
    end
  end
end
