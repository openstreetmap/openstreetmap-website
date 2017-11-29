require "test_helper"

class IssueCommentsControllerTest < ActionController::TestCase
  def test_comment_by_normal_user
    issue = create(:issue)

    # Login as normal user
    session[:user] = create(:user).id

    post :create, :params => { :issue_id => issue.id }
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_comment
    issue = create(:issue)

    # Login as administrator
    session[:user] = create(:administrator_user).id

    post :create, :params => { :issue_id => issue.id, :issue_comment => { :body => "test comment" } }
    assert_response :redirect
    assert_redirected_to issue
    assert_equal 1, issue.comments.length
  end
end
