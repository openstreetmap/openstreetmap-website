require "test_helper"

class IssuesControllerTest < ActionDispatch::IntegrationTest
  def test_index
    # Access issues list without login
    get issues_path
    assert_response :redirect
    assert_redirected_to login_path(:referer => issues_path)

    # Access issues list as normal user
    session_for(create(:user))
    get issues_path
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Access issues list as administrator
    session_for(create(:administrator_user))
    get issues_path
    assert_response :success

    # Access issues list as moderator
    session_for(create(:moderator_user))
    get issues_path
    assert_response :success
  end

  def test_show_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    # Access issue without login
    get issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to login_path(:referer => issue_path(issue))

    # Access issue as normal user
    session_for(create(:user))
    get issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Access issue as administrator
    session_for(create(:administrator_user))
    get issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found

    # Access issue as moderator
    session_for(create(:moderator_user))
    get issue_path(:id => issue)
    assert_response :success
  end

  def test_show_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    # Access issue without login
    get issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to login_path(:referer => issue_path(issue))

    # Access issue as normal user
    session_for(create(:user))
    get issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Access issue as moderator
    session_for(create(:moderator_user))
    get issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found

    # Access issue as administrator
    session_for(create(:administrator_user))
    get issue_path(:id => issue)
    assert_response :success
  end

  def test_resolve_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    # Resolve issue without login
    post resolve_issue_path(:id => issue)
    assert_response :forbidden

    # Resolve issue as normal user
    session_for(create(:user))
    post resolve_issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Resolve issue as administrator
    session_for(create(:administrator_user))
    post resolve_issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found
    assert_not issue.reload.resolved?

    # Resolve issue as moderator
    session_for(create(:moderator_user))
    post resolve_issue_path(:id => issue)
    assert_response :redirect
    assert issue.reload.resolved?
  end

  def test_resolve_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    # Resolve issue without login
    post resolve_issue_path(:id => issue)
    assert_response :forbidden

    # Resolve issue as normal user
    session_for(create(:user))
    post resolve_issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Resolve issue as moderator
    session_for(create(:moderator_user))
    post resolve_issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found
    assert_not issue.reload.resolved?

    # Resolve issue as administrator
    session_for(create(:administrator_user))
    post resolve_issue_path(:id => issue)
    assert_response :redirect
    assert issue.reload.resolved?
  end

  def test_ignore_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    # Ignore issue without login
    post ignore_issue_path(:id => issue)
    assert_response :forbidden

    # Ignore issue as normal user
    session_for(create(:user))
    post ignore_issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Ignore issue as administrator
    session_for(create(:administrator_user))
    post ignore_issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found
    assert_not issue.reload.ignored?

    # Ignore issue as moderator
    session_for(create(:moderator_user))
    post ignore_issue_path(:id => issue)
    assert_response :redirect
    assert issue.reload.ignored?
  end

  def test_ignore_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    # Ignore issue without login
    post ignore_issue_path(:id => issue)
    assert_response :forbidden

    # Ignore issue as normal user
    session_for(create(:user))
    post ignore_issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Ignore issue as moderator
    session_for(create(:moderator_user))
    post ignore_issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found
    assert_not issue.reload.ignored?

    # Ignore issue as administrator
    session_for(create(:administrator_user))
    post ignore_issue_path(:id => issue)
    assert_response :redirect
    assert issue.reload.ignored?
  end

  def test_reopen_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    issue.resolve!

    # Reopen issue without login
    post reopen_issue_path(:id => issue)
    assert_response :forbidden

    # Reopen issue as normal user
    session_for(create(:user))
    post reopen_issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Reopen issue as administrator
    session_for(create(:administrator_user))
    post reopen_issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found
    assert_not issue.reload.open?

    # Reopen issue as moderator
    session_for(create(:moderator_user))
    post reopen_issue_path(:id => issue)
    assert_response :redirect
    assert issue.reload.open?
  end

  def test_reopen_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    issue.resolve!

    # Reopen issue without login
    post reopen_issue_path(:id => issue)
    assert_response :forbidden

    # Reopen issue as normal user
    session_for(create(:user))
    post reopen_issue_path(:id => issue)
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Reopen issue as moderator
    session_for(create(:moderator_user))
    post reopen_issue_path(:id => issue)
    assert_redirected_to :controller => :errors, :action => :not_found
    assert_not issue.reload.open?

    # Reopen issue as administrator
    session_for(create(:administrator_user))
    post reopen_issue_path(:id => issue)
    assert_response :redirect
    assert issue.reload.open?
  end
end
