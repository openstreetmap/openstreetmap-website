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
    # this is redirected because there are no issues?!
    assert_response :redirect
    assert_redirected_to issues_path

    # Access issues_path by moderator
    session[:user] = create(:moderator_user).id
    get :index
    # this is redirected because there are no issues?!
    assert_response :redirect
    assert_redirected_to issues_path
  end

  def test_new_issue_without_login
    # Test creation of a new issue and a new report without logging in
    get :new, :params => { :reportable_id => 1, :reportable_type => "User", :reported_user_id => 1 }
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_issue_path(:reportable_id => 1, :reportable_type => "User", :reported_user_id => 1))
  end

  def test_new_issue_after_login
    # Test creation of a new issue and a new report
    target_user = create(:user)

    # Login
    session[:user] = create(:user).id

    assert_equal Issue.count, 0

    # Create an Issue and a report
    get :new, :params => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
    assert_response :success
    assert_difference "Issue.count", 1 do
      details = "Details of a report"
      post :create,
           :params => {
             :report => { :details => details },
             :report_type => "[OFFENSIVE]",
             :issue => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
           }
    end
    assert_equal Issue.count, 1
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_new_report_with_incomplete_details
    # Test creation of a new issue and a new report
    target_user = create(:user)

    # Login
    session[:user] = create(:user).id

    assert_equal Issue.count, 0

    # Create an Issue and a report
    get :new, :params => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
    assert_response :success
    assert_difference "Issue.count", 1 do
      details = "Details of a report"
      post :create,
           :params => {
             :report => { :details => details },
             :report_type => "[OFFENSIVE]",
             :issue => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
           }
    end
    assert_equal Issue.count, 1
    assert_response :redirect
    assert_redirected_to root_path

    get :new, :params => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
    assert_response :success

    # Report without report_type
    assert_no_difference "Issue.count" do
      details = "Details of another report under the same issue"
      post :create,
           :params => {
             :report => { :details => details },
             :issue => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
           }
    end
    assert_response :redirect
    assert_equal Issue.find_by(:reportable_id => target_user.id, :reportable_type => "User").reports.count, 1

    # Report without details
    assert_no_difference "Issue.count" do
      post :create,
           :params => {
             :report_type => "[OFFENSIVE]",
             :issue => { :reportable_id => 1, :reportable_type => "User", :reported_user_id => 2 }
           }
    end
    assert_response :redirect
    assert_equal Issue.find_by(:reportable_id => target_user.id, :reportable_type => "User").reports.count, 1
  end

  def test_new_report_with_complete_details
    # Test creation of a new issue and a new report
    target_user = create(:user)

    # Login
    session[:user] = create(:user).id

    assert_equal Issue.count, 0

    # Create an Issue and a report
    get :new, :params => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
    assert_response :success
    assert_difference "Issue.count", 1 do
      details = "Details of a report"
      post :create,
           :params => {
             :report => { :details => details },
             :report_type => "[OFFENSIVE]",
             :issue => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
           }
    end
    assert_equal Issue.count, 1
    assert_response :redirect
    assert_redirected_to root_path

    # Create a report for an existing Issue
    get :new, :params => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
    assert_response :success
    assert_no_difference "Issue.count" do
      details = "Details of another report under the same issue"
      post :create,
           :params => {
             :report => { :details => details },
             :report_type => "[OFFENSIVE]",
             :issue => { :reportable_id => target_user.id, :reportable_type => "User", :reported_user_id => target_user.id }
           }
    end
    assert_response :redirect
    report_count = Issue.find_by(:reportable_id => target_user.id, :reportable_type => "User").reports.count
    assert_equal report_count, 2
  end

  def test_change_status_by_normal_user
    target_user = create(:user)
    issue = create(:issue, :reportable => target_user, :reported_user => target_user)

    # Login as normal user
    session[:user] = create(:user).id

    assert_equal Issue.count, 1

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
    assert_equal Issue.find_by(:reportable_id => target_user.id, :reportable_type => "User").resolved?, true
    assert_response :redirect

    # Test 'Reopen'
    get :reopen, :params => { :id => issue.id }
    assert_equal Issue.find_by(:reportable_id => target_user.id, :reportable_type => "User").open?, true
    assert_response :redirect

    # Test 'Ignored'
    get :ignore, :params => { :id => issue.id }
    assert_equal Issue.find_by(:reportable_id => target_user, :reportable_type => "User").ignored?, true
    assert_response :redirect
  end

  def test_search_issues
    good_user = create(:user)
    bad_user = create(:user)
    create(:issue, :reportable => bad_user, :reported_user => bad_user, :issue_type => "administrator")
    # Login as administrator
    session[:user] = create(:administrator_user).id

    # No issues against the user
    get :index, :params => { :search_by_user => good_user.display_name }
    assert_response :redirect
    assert_redirected_to issues_path

    # User doesn't exist
    get :index, :params => { :search_by_user => "test1000" }
    assert_response :redirect
    assert_redirected_to issues_path

    # Find Issue against bad_user
    get :index, :params => { :search_by_user => bad_user.display_name }
    assert_response :success
  end
end
