require "test_helper"

module Accounts
  class PdDeclarationsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/account/pd_declaration", :method => :get },
        { :controller => "accounts/pd_declarations", :action => "show" }
      )
    end

    def test_show_not_logged_in
      get account_pd_declaration_path

      assert_redirected_to login_path(:referer => account_pd_declaration_path)
    end

    def test_show_agreed
      user = create(:user)
      session_for(user)

      get account_pd_declaration_path

      assert_response :success
    end
  end
end
