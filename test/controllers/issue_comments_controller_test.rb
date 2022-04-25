require "test_helper"

class IssueCommentsControllerTest < ActionDispatch::IntegrationTest
  def test_comment_by_normal_user
    issue = create(:issue)

    # Login as normal user
    session_for(create(:user))

    post issue_comments_path(:issue_id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden
    assert_equal 0, issue.comments.length
  end

  def test_comment
    issue = create(:issue)

    # Login as administrator
    session_for(create(:administrator_user))

    post issue_comments_path(:issue_id => issue, :issue_comment => { :body => "test comment" })
    assert_response :redirect
    assert_redirected_to issue
    assert_equal 1, issue.comments.length
  end
end
