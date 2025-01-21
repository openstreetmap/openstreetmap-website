require "test_helper"

module Users
  class DiaryCommentsControllerTest < ActionDispatch::IntegrationTest
    def setup
      super
      # Create the default language for diary entries
      create(:language, :code => "en")
    end

    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/user/username/diary_comments", :method => :get },
        { :controller => "users/diary_comments", :action => "index", :user_display_name => "username" }
      )

      get "/user/username/diary/comments/1"
      assert_redirected_to "/user/username/diary_comments"

      get "/user/username/diary/comments"
      assert_redirected_to "/user/username/diary_comments"
    end

    def test_index
      user = create(:user)
      other_user = create(:user)
      suspended_user = create(:user, :suspended)
      deleted_user = create(:user, :deleted)

      # Test a user with no comments
      get user_diary_comments_path(user)
      assert_response :success
      assert_template :index
      assert_select "h4", :html => "No comments"

      # Test a user with a comment
      create(:diary_comment, :user => other_user)

      get user_diary_comments_path(other_user)
      assert_response :success
      assert_template :index
      assert_dom "a[href='#{user_path(other_user)}']", :text => other_user.display_name
      assert_select "table.table-striped tbody" do
        assert_select "tr", :count => 1
      end

      # Test a suspended user
      get user_diary_comments_path(suspended_user)
      assert_response :not_found

      # Test a deleted user
      get user_diary_comments_path(deleted_user)
      assert_response :not_found
    end

    def test_index_invalid_paged
      user = create(:user)

      %w[-1 0 fred].each do |id|
        get user_diary_comments_path(user, :before => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request

        get user_diary_comments_path(user, :after => id)
        assert_redirected_to :controller => "/errors", :action => :bad_request
      end
    end
  end
end
