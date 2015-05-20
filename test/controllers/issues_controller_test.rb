require 'test_helper'

class IssuesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  def test_new_issue
    # Test creation of a new issue and a new report
    get :new, {reportable_id: 1, reportable_type: "IssueOne", user: 1}
    assert_response :success
    assert_difference "Issue.count",1 do 
      details = "Details of a report"
      post :create, { :report => { :deatils => details},
                      :issue => { reportable_id: 1, reportable_type: "IssueOne", user: 1} }
    end
    assert_response :redirect
  end

  def test_new_report
    # Test creation of a new report for an existing issue
    get :new, {reportable_id: 1, reportable_type: "IssueOne", user: 1}
    assert_response :success
    assert_difference "Issue.count",1 do 
      details = "Details of a report"
      post :create, { :report => { :details => details},
                      :issue => { reportable_id: 1, reportable_type: "IssueOne", user: 1} }
    end
    assert_response :redirect
    
    get :new, {reportable_id: 1, reportable_type: "IssueOne", user: 1}
    assert_response :success
    assert_no_difference "Issue.count" do
      details = "Details of another report under the same issue"
      post :create, { :report => { :details => details},
                      :issue => { reportable_id: 1, reportable_type: "IssueOne", user: 1} }
    end
    assert_response :redirect
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"IssueOne").reports.count,2
  end

  def test_change_status
    # Create Issue
    get :new, {reportable_id: 1, reportable_type: "IssueOne", user: 1}
    assert_response :success
    assert_difference "Issue.count",1 do 
      details = "Details of a report"
      post :create, { :report => { :deatils => details},
                      :issue => { reportable_id: 1, reportable_type: "IssueOne", user: 1} }
    end
    assert_response :redirect

    # Test 'Resolved'
    get :resolve, id: Issue.find_by_reportable_id_and_reportable_type(1,"IssueOne").id
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"IssueOne").resolved?, true
    assert_response :redirect

    # Test 'Reopen'
    get :reopen, id: Issue.find_by_reportable_id_and_reportable_type(1,"IssueOne").id
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"IssueOne").open?, true
    assert_response :redirect

    # Test 'Ignored'
    get :ignore, id: Issue.find_by_reportable_id_and_reportable_type(1,"IssueOne").id
    assert_equal Issue.find_by_reportable_id_and_reportable_type(1,"IssueOne").ignored?, true
    assert_response :redirect
  end

end
