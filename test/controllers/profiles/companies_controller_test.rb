# frozen_string_literal: true

require "test_helper"

module Profiles
  class CompaniesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/profile/company", :method => :get },
        { :controller => "profiles/companies", :action => "show" }
      )
      assert_routing(
        { :path => "/profile/company", :method => :put },
        { :controller => "profiles/companies", :action => "update" }
      )
    end

    def test_show
      user = create(:user)
      session_for(user)

      get profile_company_path

      assert_response :success
      assert_template :show
    end

    def test_show_unauthorized
      get profile_company_path

      assert_redirected_to login_path(:referer => profile_company_path)
    end

    def test_update
      user = create(:user)
      session_for(user)

      put profile_company_path, :params => { :user => { :company => "new company", :description => user.description } }

      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Profile company updated."

      user.reload
      assert_equal "new company", user.company
    end
  end
end
