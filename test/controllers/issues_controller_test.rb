require 'test_helper'

class IssuesControllerTest < ActionController::TestCase
  fixtures :users,:user_roles

  def test_view_dashboard_without_auth
    # Access issues_path without login
    get :index
    assert_response :redirect
    assert_redirected_to login_path(:referer => issues_path)

    # Access issues_path as normal user
    session[:user] = users(:normal_user).id
    get :index
    assert_response :redirect
    assert_redirected_to root_path

    # Access issues_path by admin
    session[:user] = users(:administrator_user).id
    get :index
    assert_response :success

    # Access issues_path by moderator
    session[:user]= users(:moderator_user).id
    get :index
    assert_response :success
  end

  def test_new_issue_without_login
    # Test creation of a new issue and a new report without logging in
    get :new, {reportable_id: 1, reportable_type: "User", reported_user_id: 1}
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_issue_path(:reportable_id=>1, :reportable_type=>"User",:reported_user_id=> 1))
  end

  def test_new_issue_after_login
    # Test creation of a new issue and a new report

    # Login
    session[:user] = users(:normal_user).id

    assert_equal Issue.count,0
    
    # Create an Issue and a report  
    get :new, {reportable_id: 1, reportable_type: "User", reported_user_id: 2}
    assert_response :success
    assert_difference "Issue.count",1 do
      details = "Details of a report"
      post :create, { :report => { :details => details},
                    :report_type => "[OFFENSIVE]",
                    :issue => { reportable_id: 1, reportable_type: "User", reported_user_id: 2} }
    end
    assert_equal Issue.count,1
    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_new_report_with_incomplete_details
    # Test creation of a new issue and a new report

    # Login
    session[:user] = users(:normal_user).id

    assert_equal Issue.count,0

    # Create an Issue and a report
    get :new, {reportable_id: 1, reportable_type: "User", reported_user_id: 2}
    assert_response :success
    assert_difference "Issue.count",1 do
      details = "Details of a report"
      post :create, { :report => { :details => details},
                      :report_type => "[OFFENSIVE]",
                      :issue => { reportable_id: 1, reportable_type: "User", reported_user_id: 2} }
    end 
    assert_equal Issue.count,1
    assert_response :redirect
    assert_redirected_to root_path
    
    get :new, {reportable_id: 1, reportable_type: "User", reported_user_id: 2}
    assert_response :success

    # Report without report_type
    assert_no_difference "Issue.count" do
      details = "Details of another report under the same issue"
      post :create, { :report => { :details => details},
                      :issue => { reportable_id: 1, reportable_type: "User", reported_user_id: 2} }
    end
    assert_response :redirect
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"User").reports.count,1

    # Report without details
    assert_no_difference "Issue.count" do
      post :create, { :report_type => "[OFFENSIVE]", 
                      :issue => { reportable_id: 1, reportable_type: "User", reported_user_id: 2} }
    end
    assert_response :redirect
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"User").reports.count,1
  end

  def test_new_report_with_complete_details
    # Test creation of a new issue and a new report

    # Login
    session[:user] = users(:normal_user).id

    assert_equal Issue.count,0

    # Create an Issue and a report
    get :new, {reportable_id: 1, reportable_type: "User", reported_user_id: 2}
    assert_response :success
    assert_difference "Issue.count",1 do
      details = "Details of a report"
      post :create, { :report => { :details => details},
                    :report_type => "[OFFENSIVE]",
                    :issue => { reportable_id: 1, reportable_type: "User", reported_user_id: 2} }
    end
    assert_equal Issue.count,1
    assert_response :redirect
    assert_redirected_to root_path
    
    # Create a report for an existing Issue
    get :new, {reportable_id: 1, reportable_type: "User", reported_user_id: 2}
    assert_response :success
    assert_no_difference "Issue.count" do
      details = "Details of another report under the same issue"
      post :create, { :report => { :details => details},
                      :report_type => "[OFFENSIVE]",      
                      :issue => { reportable_id: 1, reportable_type: "User", reported_user_id: 2} }
    end
    assert_response :redirect
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"User").reports.count,2
  end

  def test_change_status_by_normal_user
    # Login as normal user
    session[:user] = users(:normal_user).id
    
    # Create Issue
    test_new_issue_after_login    
    assert_equal Issue.count,1
    
    get :resolve, id: Issue.find_by_reportable_id_and_reportable_type(1,"User").id

    assert_response :redirect
    assert_redirected_to root_path
  end

  def test_change_status_by_admin
    # Login as normal user
    session[:user] = users(:normal_user).id

    # Create Issue
    test_new_issue_after_login
    assert_equal Issue.count,1
    assert_response :redirect

    # Login as administrator
    session[:user] = users(:administrator_user).id
   
    # Test 'Resolved'
    get :resolve, id: Issue.find_by_reportable_id_and_reportable_type(1,"User").id
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"User").resolved?, true
    assert_response :redirect

    # Test 'Reopen'
    get :reopen, id: Issue.find_by_reportable_id_and_reportable_type(1,"User").id
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"User").open?, true
    assert_response :redirect

    # Test 'Ignored'
    get :ignore, id: Issue.find_by_reportable_id_and_reportable_type(1,"User").id
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"User").ignored?, true
    assert_response :redirect
  end

  def test_search_issues
    # Login as administrator
    session[:user] = users(:administrator_user).id

    # No issues against the user
    get :index, search_by_user: "test1"
    assert_response :redirect
    assert_redirected_to issues_path

    # User doesn't exist
    get :index, search_by_user: "test1000"
    assert_response :redirect
    assert_redirected_to issues_path

    # Create Issue against user_id:2
    test_new_issue_after_login
    assert_equal Issue.count,1
    assert_equal Issue.first.reported_user_id,2

    session[:user] = users(:administrator_user).id

    # Find Issue against user_id:2
    get :index, search_by_user: "test2"
    assert_response :success
  end

end
