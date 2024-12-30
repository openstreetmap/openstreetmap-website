require "test_helper"
require_relative "../user_blocks/table_test_helper"

module Users
  class ReceivedBlocksControllerTest < ActionDispatch::IntegrationTest
    include UserBlocks::TableTestHelper

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/user/username/blocks", :method => :get },
        { :controller => "users/received_blocks", :action => "show", :user_display_name => "username" }
      )
      assert_routing(
        { :path => "/user/username/blocks/edit", :method => :get },
        { :controller => "users/received_blocks", :action => "edit", :user_display_name => "username" }
      )
      assert_routing(
        { :path => "/user/username/blocks", :method => :delete },
        { :controller => "users/received_blocks", :action => "destroy", :user_display_name => "username" }
      )
    end

    def test_show
      blocked_user = create(:user)
      unblocked_user = create(:user)
      normal_user = create(:user)
      active_block = create(:user_block, :user => blocked_user)
      revoked_block = create(:user_block, :revoked, :user => blocked_user)
      expired_block = create(:user_block, :expired, :user => unblocked_user)

      # Asking for a list of blocks with a bogus user name should fail
      get user_received_blocks_path("non_existent_user")
      assert_response :not_found
      assert_template "users/no_such_user"
      assert_select "h1", "The user non_existent_user does not exist"

      # Check the list of blocks for a user that has never been blocked
      get user_received_blocks_path(normal_user)
      assert_response :success
      assert_select "table#block_list", false
      assert_select "p", "#{normal_user.display_name} has not been blocked yet."

      # Check the list of blocks for a user that is currently blocked
      get user_received_blocks_path(blocked_user)
      assert_response :success
      assert_select "h1 a[href='#{user_path blocked_user}']", :text => blocked_user.display_name
      assert_select "a.active[href='#{user_received_blocks_path blocked_user}']"
      assert_select "table#block_list tbody", :count => 1 do
        assert_select "tr", 2
        assert_select "a[href='#{user_block_path(active_block)}']", 1
        assert_select "a[href='#{user_block_path(revoked_block)}']", 1
      end

      # Check the list of blocks for a user that has previously been blocked
      get user_received_blocks_path(unblocked_user)
      assert_response :success
      assert_select "h1 a[href='#{user_path unblocked_user}']", :text => unblocked_user.display_name
      assert_select "a.active[href='#{user_received_blocks_path unblocked_user}']"
      assert_select "table#block_list tbody", :count => 1 do
        assert_select "tr", 1
        assert_select "a[href='#{user_block_path(expired_block)}']", 1
      end
    end

    def test_show_paged
      user = create(:user)
      user_blocks = create_list(:user_block, 50, :user => user).reverse
      next_path = user_received_blocks_path(user)

      get next_path
      assert_response :success
      check_user_blocks_table user_blocks[0...20]
      check_no_page_link "Newer Blocks"
      next_path = check_page_link "Older Blocks"

      get next_path
      assert_response :success
      check_user_blocks_table user_blocks[20...40]
      check_page_link "Newer Blocks"
      next_path = check_page_link "Older Blocks"

      get next_path
      assert_response :success
      check_user_blocks_table user_blocks[40...50]
      check_page_link "Newer Blocks"
      check_no_page_link "Older Blocks"
    end

    def test_show_invalid_paged
      user = create(:user)

      %w[-1 0 fred].each do |id|
        get user_received_blocks_path(user, :before => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request

        get user_received_blocks_path(user, :after => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request
      end
    end

    ##
    # test the revoke all blocks page
    def test_edit
      blocked_user = create(:user)
      create(:user_block, :user => blocked_user)

      # Asking for the revoke all blocks page with a bogus user name should fail
      get user_received_blocks_path("non_existent_user")
      assert_response :not_found

      # Check that the revoke all blocks page requires us to login
      get edit_user_received_blocks_path(blocked_user)
      assert_redirected_to login_path(:referer => edit_user_received_blocks_path(blocked_user))

      # Login as a normal user
      session_for(create(:user))

      # Check that normal users can't load the revoke all blocks page
      get edit_user_received_blocks_path(blocked_user)
      assert_redirected_to :controller => "/errors", :action => "forbidden"

      # Login as a moderator
      session_for(create(:moderator_user))

      # Check that the revoke all blocks page loads for moderators
      get edit_user_received_blocks_path(blocked_user)
      assert_response :success
      assert_select "h1 a[href='#{user_path blocked_user}']", :text => blocked_user.display_name
    end

    ##
    # test the revoke all action
    def test_destroy
      blocked_user = create(:user)
      active_block1 = create(:user_block, :user => blocked_user)
      active_block2 = create(:user_block, :user => blocked_user)
      expired_block1 = create(:user_block, :expired, :user => blocked_user)
      blocks = [active_block1, active_block2, expired_block1]
      moderator_user = create(:moderator_user)

      assert_predicate active_block1, :active?
      assert_predicate active_block2, :active?
      assert_not_predicate expired_block1, :active?

      # Check that normal users can't revoke all blocks
      session_for(create(:user))
      delete user_received_blocks_path(blocked_user, :confirm => true)
      assert_redirected_to :controller => "/errors", :action => "forbidden"

      blocks.each(&:reload)
      assert_predicate active_block1, :active?
      assert_predicate active_block2, :active?
      assert_not_predicate expired_block1, :active?

      # Check that confirmation is required
      session_for(moderator_user)
      delete user_received_blocks_path(blocked_user)

      blocks.each(&:reload)
      assert_predicate active_block1, :active?
      assert_predicate active_block2, :active?
      assert_not_predicate expired_block1, :active?

      # Check that moderators can revoke all blocks
      delete user_received_blocks_path(blocked_user, :confirm => true)
      assert_redirected_to user_received_blocks_path(blocked_user)

      blocks.each(&:reload)
      assert_not_predicate active_block1, :active?
      assert_not_predicate active_block2, :active?
      assert_not_predicate expired_block1, :active?
      assert_equal moderator_user, active_block1.revoker
      assert_equal moderator_user, active_block2.revoker
      assert_not_equal moderator_user, expired_block1.revoker
    end
  end
end
