# frozen_string_literal: true

require "test_helper"

module Issues
  class DataControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/issues/1/reporters", :method => :get },
        { :controller => "issues/reporters", :action => "index", :issue_id => "1" }
      )
    end

    def test_index_missing_issue_as_moderator
      session_for(create(:moderator_user))
      get issue_reporters_path(999111)

      assert_redirected_to :controller => "/errors", :action => :not_found
    end

    def test_index_missing_issue_as_administrator
      session_for(create(:administrator_user))
      get issue_reporters_path(999111)

      assert_redirected_to :controller => "/errors", :action => :not_found
    end

    def test_index_assigned_to_moderator_as_unauthorized
      issue = create(:issue, :assigned_role => "moderator")

      get issue_reporters_path(issue)

      assert_redirected_to login_path(:referer => issue_reporters_path(issue))
    end

    def test_index_assigned_to_moderator_as_regular_user
      issue = create(:issue, :assigned_role => "moderator")

      session_for(create(:user))
      get issue_reporters_path(issue)

      assert_redirected_to :controller => "/errors", :action => :forbidden
    end

    def test_index_assigned_to_moderator_as_administrator
      issue = create(:issue, :assigned_role => "moderator")

      session_for(create(:administrator_user))
      get issue_reporters_path(issue)

      assert_redirected_to :controller => "/errors", :action => :not_found
    end

    def test_index_assigned_to_moderator_as_moderator
      issue = create(:issue, :assigned_role => "moderator")

      session_for(create(:moderator_user))
      get issue_reporters_path(issue)

      assert_response :success
    end

    def test_index_assigned_to_administrator_as_unauthorized
      issue = create(:issue, :assigned_role => "administrator")

      get issue_reporters_path(issue)

      assert_redirected_to login_path(:referer => issue_reporters_path(issue))
    end

    def test_index_assigned_to_administrator_as_regular_user
      issue = create(:issue, :assigned_role => "administrator")

      session_for(create(:user))
      get issue_reporters_path(issue)

      assert_redirected_to :controller => "/errors", :action => :forbidden
    end

    def test_index_assigned_to_administrator_as_moderator
      issue = create(:issue, :assigned_role => "administrator")

      session_for(create(:moderator_user))
      get issue_reporters_path(issue)

      assert_redirected_to :controller => "/errors", :action => :not_found
    end

    def test_index_assigned_to_administrator_as_administrator
      issue = create(:issue, :assigned_role => "administrator")

      session_for(create(:administrator_user))
      get issue_reporters_path(issue)

      assert_response :success
    end
  end
end
