require "test_helper"

class IssuesControllerTest < ActionController::TestCase
  def test_index
    # Access issues list without login
    get :index
    assert_response :redirect
    assert_redirected_to login_path(:referer => issues_path)

    # Access issues list as normal user
    session[:user] = create(:user).id
    get :index
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Access issues list as administrator
    session[:user] = create(:administrator_user).id
    get :index
    assert_response :success

    # Access issues list as moderator
    session[:user] = create(:moderator_user).id
    get :index
    assert_response :success
  end

  def test_show_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    # Access issue without login
    get :show, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => issue_path(issue))

    # Access issue as normal user
    session[:user] = create(:user).id
    get :show, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Access issue as administrator
    session[:user] = create(:administrator_user).id
    get :show, :params => { :id => issue.id }
    assert_response :not_found

    # Access issue as moderator
    session[:user] = create(:moderator_user).id
    get :show, :params => { :id => issue.id }
    assert_response :success
  end

  def test_show_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    # Access issue without login
    get :show, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => issue_path(issue))

    # Access issue as normal user
    session[:user] = create(:user).id
    get :show, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Access issue as moderator
    session[:user] = create(:moderator_user).id
    get :show, :params => { :id => issue.id }
    assert_response :not_found

    # Access issue as administrator
    session[:user] = create(:administrator_user).id
    get :show, :params => { :id => issue.id }
    assert_response :success
  end

  def test_resolve_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    # Resolve issue without login
    get :resolve, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => resolve_issue_path(issue))

    # Resolve issue as normal user
    session[:user] = create(:user).id
    get :resolve, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Resolve issue as administrator
    session[:user] = create(:administrator_user).id
    get :resolve, :params => { :id => issue.id }
    assert_response :not_found
    assert_equal false, issue.reload.resolved?

    # Resolve issue as moderator
    session[:user] = create(:moderator_user).id
    get :resolve, :params => { :id => issue.id }
    assert_response :redirect
    assert_equal true, issue.reload.resolved?
  end

  def test_resolve_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    # Resolve issue without login
    get :resolve, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => resolve_issue_path(issue))

    # Resolve issue as normal user
    session[:user] = create(:user).id
    get :resolve, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Resolve issue as moderator
    session[:user] = create(:moderator_user).id
    get :resolve, :params => { :id => issue.id }
    assert_response :not_found
    assert_equal false, issue.reload.resolved?

    # Resolve issue as administrator
    session[:user] = create(:administrator_user).id
    get :resolve, :params => { :id => issue.id }
    assert_response :redirect
    assert_equal true, issue.reload.resolved?
  end

  def test_ignore_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    # Ignore issue without login
    get :ignore, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => ignore_issue_path(issue))

    # Ignore issue as normal user
    session[:user] = create(:user).id
    get :ignore, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Ignore issue as administrator
    session[:user] = create(:administrator_user).id
    get :ignore, :params => { :id => issue.id }
    assert_response :not_found
    assert_equal false, issue.reload.ignored?

    # Ignore issue as moderator
    session[:user] = create(:moderator_user).id
    get :ignore, :params => { :id => issue.id }
    assert_response :redirect
    assert_equal true, issue.reload.ignored?
  end

  def test_ignore_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    # Ignore issue without login
    get :ignore, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => ignore_issue_path(issue))

    # Ignore issue as normal user
    session[:user] = create(:user).id
    get :ignore, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Ignore issue as moderator
    session[:user] = create(:moderator_user).id
    get :ignore, :params => { :id => issue.id }
    assert_response :not_found
    assert_equal false, issue.reload.ignored?

    # Ignore issue as administrator
    session[:user] = create(:administrator_user).id
    get :ignore, :params => { :id => issue.id }
    assert_response :redirect
    assert_equal true, issue.reload.ignored?
  end

  def test_reopen_moderator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "moderator")

    issue.resolve!

    # Reopen issue without login
    get :reopen, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => reopen_issue_path(issue))

    # Reopen issue as normal user
    session[:user] = create(:user).id
    get :reopen, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Reopen issue as administrator
    session[:user] = create(:administrator_user).id
    get :reopen, :params => { :id => issue.id }
    assert_response :not_found
    assert_equal false, issue.reload.open?

    # Reopen issue as moderator
    session[:user] = create(:moderator_user).id
    get :reopen, :params => { :id => issue.id }
    assert_response :redirect
    assert_equal true, issue.reload.open?
  end

  def test_reopen_administrator
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user, :assigned_role => "administrator")

    issue.resolve!

    # Reopen issue without login
    get :reopen, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to login_path(:referer => reopen_issue_path(issue))

    # Reopen issue as normal user
    session[:user] = create(:user).id
    get :reopen, :params => { :id => issue.id }
    assert_response :redirect
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Reopen issue as moderator
    session[:user] = create(:moderator_user).id
    get :reopen, :params => { :id => issue.id }
    assert_response :not_found
    assert_equal false, issue.reload.open?

    # Reopen issue as administrator
    session[:user] = create(:administrator_user).id
    get :reopen, :params => { :id => issue.id }
    assert_response :redirect
    assert_equal true, issue.reload.open?
  end
end
