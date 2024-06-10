require "test_helper"

class DiaryCommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    # Create the default language for diary entries
    create(:language, :code => "en")
  end

  def test_routes
    assert_routing(
      { :path => "/user/username/diary/comments", :method => :get },
      { :controller => "diary_comments", :action => "index", :display_name => "username" }
    )

    get "/user/username/diary/comments/1"
    assert_redirected_to "/user/username/diary/comments"
  end

  def test_index
    user = create(:user)
    other_user = create(:user)
    suspended_user = create(:user, :suspended)
    deleted_user = create(:user, :deleted)

    # Test a user with no comments
    get diary_comments_path(:display_name => user.display_name)
    assert_response :success
    assert_template :index
    assert_select "h4", :html => "No diary comments"

    # Test a user with a comment
    create(:diary_comment, :user => other_user)

    get diary_comments_path(:display_name => other_user.display_name)
    assert_response :success
    assert_template :index
    assert_dom "a[href='#{user_path(other_user)}']", :text => other_user.display_name
    assert_select "table.table-striped tbody" do
      assert_select "tr", :count => 1
    end

    # Test a suspended user
    get diary_comments_path(:display_name => suspended_user.display_name)
    assert_response :not_found

    # Test a deleted user
    get diary_comments_path(:display_name => deleted_user.display_name)
    assert_response :not_found
  end

  def test_index_invalid_paged
    user = create(:user)

    %w[-1 fred].each do |id|
      get diary_comments_path(:display_name => user.display_name, :before => id)
      assert_redirected_to :controller => :errors, :action => :bad_request

      get diary_comments_path(:display_name => user.display_name, :after => id)
      assert_redirected_to :controller => :errors, :action => :bad_request
    end
  end
end
