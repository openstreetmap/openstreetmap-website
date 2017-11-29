require "test_helper"

class IssuesControllerTest < ActionController::TestCase
  teardown do
    # cleanup any emails set off by the test
    ActionMailer::Base.deliveries.clear
  end

  def test_view_dashboard_without_auth
    # Access issues_path without login
    get :index
    assert_response :redirect
    assert_redirected_to login_path(:referer => issues_path)

    # Access issues_path as normal user
    session[:user] = create(:user).id
    get :index
    assert_response :redirect
    assert_redirected_to root_path

    # Access issues_path by admin
    session[:user] = create(:administrator_user).id
    get :index
    assert_response :success

    # Access issues_path by moderator
    session[:user] = create(:moderator_user).id
    get :index
    assert_response :success
  end

  def test_change_status_by_normal_user
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user)

    # Login as normal user
    session[:user] = create(:user).id

    assert_equal 1, Issue.count

    get :resolve, :params => { :id => issue.id }

    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_change_status_by_admin
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user)

    # Login as administrator
    session[:user] = create(:administrator_user).id

    # Test 'Resolved'
    get :resolve, :params => { :id => issue.id }
    assert_equal true, Issue.find_by(:reportable_id => target_user.id, :reportable_type => "User").resolved?
    assert_response :redirect

    # Test 'Reopen'
    get :reopen, :params => { :id => issue.id }
    assert_equal true, Issue.find_by(:reportable_id => target_user.id, :reportable_type => "User").open?
    assert_response :redirect

    # Test 'Ignored'
    get :ignore, :params => { :id => issue.id }
    assert_equal true, Issue.find_by(:reportable_id => target_user, :reportable_type => "User").ignored?
    assert_response :redirect
  end
end
