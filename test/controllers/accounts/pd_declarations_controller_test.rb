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
      assert_routing(
        { :path => "/account/pd_declaration", :method => :post },
        { :controller => "accounts/pd_declarations", :action => "create" }
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

    def test_create_not_logged_in
      post account_pd_declaration_path

      assert_response :forbidden
    end

    def test_create
      user = create(:user)
      session_for(user)

      post account_pd_declaration_path

      assert_redirected_to edit_account_path
    end
  end
end
