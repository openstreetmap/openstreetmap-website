require "test_helper"

module Profiles
  class LocationsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/profile/location", :method => :get },
        { :controller => "profiles/locations", :action => "show" }
      )
      assert_routing(
        { :path => "/profile/location", :method => :put },
        { :controller => "profiles/locations", :action => "update" }
      )
    end

    def test_show
      user = create(:user)
      session_for(user)

      get profile_location_path

      assert_response :success
      assert_template :show
    end

    def test_show_unauthorized
      get profile_location_path

      assert_redirected_to login_path(:referer => profile_location_path)
    end
  end
end
