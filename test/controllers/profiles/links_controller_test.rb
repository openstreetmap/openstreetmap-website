require "test_helper"

module Profiles
  class LinksControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/profile/links", :method => :get },
        { :controller => "profiles/links", :action => "show" }
      )
      assert_routing(
        { :path => "/profile/links", :method => :put },
        { :controller => "profiles/links", :action => "update" }
      )
    end

    def test_show
      user = create(:user)
      session_for(user)

      get profile_links_path

      assert_response :success
      assert_template :show
    end

    def test_show_unauthorized
      get profile_links_path

      assert_redirected_to login_path(:referer => profile_links_path)
    end
  end
end
