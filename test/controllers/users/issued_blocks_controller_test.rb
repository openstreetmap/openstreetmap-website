require "test_helper"
require_relative "../user_blocks/table_test_helper"

module Users
  class IssuedBlocksControllerTest < ActionDispatch::IntegrationTest
    include UserBlocks::TableTestHelper

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/user/username/blocks_by", :method => :get },
        { :controller => "users/issued_blocks", :action => "show", :user_display_name => "username" }
      )
    end

    def test_show
      moderator_user = create(:moderator_user)
      second_moderator_user = create(:moderator_user)
      normal_user = create(:user)
      active_block = create(:user_block, :creator => moderator_user)
      expired_block = create(:user_block, :expired, :creator => second_moderator_user)
      revoked_block = create(:user_block, :revoked, :creator => second_moderator_user)

      # Asking for a list of blocks with a bogus user name should fail
      get user_issued_blocks_path("non_existent_user")
      assert_response :not_found
      assert_template "users/no_such_user"
      assert_select "h1", "The user non_existent_user does not exist"

      # Check the list of blocks given by one moderator
      get user_issued_blocks_path(moderator_user)
      assert_response :success
      assert_select "h1 a[href='#{user_path moderator_user}']", :text => moderator_user.display_name
      assert_select "a.active[href='#{user_issued_blocks_path moderator_user}']"
      assert_select "table#block_list tbody", :count => 1 do
        assert_select "tr", 1
        assert_select "a[href='#{user_block_path(active_block)}']", 1
      end

      # Check the list of blocks given by a different moderator
      get user_issued_blocks_path(second_moderator_user)
      assert_response :success
      assert_select "h1 a[href='#{user_path second_moderator_user}']", :text => second_moderator_user.display_name
      assert_select "a.active[href='#{user_issued_blocks_path second_moderator_user}']"
      assert_select "table#block_list tbody", :count => 1 do
        assert_select "tr", 2
        assert_select "a[href='#{user_block_path(expired_block)}']", 1
        assert_select "a[href='#{user_block_path(revoked_block)}']", 1
      end

      # Check the list of blocks (not) given by a normal user
      get user_issued_blocks_path(normal_user)
      assert_response :success
      assert_select "table#block_list", false
      assert_select "p", "#{normal_user.display_name} has not made any blocks yet."
    end

    def test_show_paged
      user = create(:moderator_user)
      user_blocks = create_list(:user_block, 50, :creator => user).reverse
      next_path = user_issued_blocks_path(user)

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
      user = create(:moderator_user)

      %w[-1 0 fred].each do |id|
        get user_issued_blocks_path(user, :before => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request

        get user_issued_blocks_path(user, :after => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request
      end
    end
  end
end
