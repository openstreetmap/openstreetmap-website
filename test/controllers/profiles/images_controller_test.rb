require "test_helper"

module Profiles
  class ImagesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/profile/image", :method => :get },
        { :controller => "profiles/images", :action => "show" }
      )
      assert_routing(
        { :path => "/profile/image", :method => :put },
        { :controller => "profiles/images", :action => "update" }
      )
    end

    def test_show
      user = create(:user)
      session_for(user)

      get profile_image_path

      assert_response :success
      assert_template :show
    end

    def test_show_unauthorized
      get profile_image_path

      assert_redirected_to login_path(:referer => profile_image_path)
    end
  end
end
