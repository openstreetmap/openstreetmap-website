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

    def test_update
      user = create(:user)
      session_for(user)

      # Changing to an uploaded image should work
      image = Rack::Test::UploadedFile.new("test/gpx/fixtures/a.gif", "image/gif")
      put profile_image_path, :params => { :avatar_action => "new", :user => { :avatar => image, :description => user.description } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Profile updated."
      get profile_image_path
      assert_dom "form > div > div.col-sm-10 > div.form-check > input[name=avatar_action][checked][value=?]", "keep"

      # Changing to a gravatar image should work
      put profile_image_path, :params => { :avatar_action => "gravatar", :user => { :description => user.description } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Profile updated."
      get profile_image_path
      assert_dom "form > div > div.col-sm-10 > div > div.form-check > input[name=avatar_action][checked][value=?]", "gravatar"

      # Removing the image should work
      put profile_image_path, :params => { :avatar_action => "delete", :user => { :description => user.description } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Profile updated."
      get profile_image_path
      assert_dom "form > div > div.col-sm-10 > div > input[name=avatar_action][checked]", false
      assert_dom "form > div > div.col-sm-10 > div > div.form-check > input[name=avatar_action][checked]", false
    end
  end
end
