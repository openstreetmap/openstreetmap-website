require "test_helper"

module Profiles
  class DescriptionsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/profile/description", :method => :get },
        { :controller => "profiles/descriptions", :action => "show" }
      )
      assert_routing(
        { :path => "/profile/description", :method => :put },
        { :controller => "profiles/descriptions", :action => "update" }
      )

      get "/profile"
      assert_redirected_to "/profile/description"

      get "/profile/edit"
      assert_redirected_to "/profile/description"
    end

    def test_show
      user = create(:user)
      session_for(user)

      get profile_description_path

      assert_response :success
      assert_template :show
    end

    def test_show_unauthorized
      get profile_description_path

      assert_redirected_to login_path(:referer => profile_description_path)
    end

    def test_update
      user = create(:user)
      session_for(user)

      # Updating the description should work
      put profile_description_path, :params => { :user => { :description => "new description" } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_select ".alert-success", /^Profile updated./
      assert_select "div", "new description"

      # Changing to an uploaded image should work
      image = Rack::Test::UploadedFile.new("test/gpx/fixtures/a.gif", "image/gif")
      put profile_description_path, :params => { :avatar_action => "new", :user => { :avatar => image, :description => user.description } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_select ".alert-success", /^Profile updated./
      get profile_description_path
      assert_select "form > fieldset > div > div.col-sm-10 > div.form-check > input[name=avatar_action][checked][value=?]", "keep"

      # Changing to a gravatar image should work
      put profile_description_path, :params => { :avatar_action => "gravatar", :user => { :description => user.description } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_select ".alert-success", /^Profile updated./
      get profile_description_path
      assert_select "form > fieldset > div > div.col-sm-10 > div > div.form-check > input[name=avatar_action][checked][value=?]", "gravatar"

      # Removing the image should work
      put profile_description_path, :params => { :avatar_action => "delete", :user => { :description => user.description } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_select ".alert-success", /^Profile updated./
      get profile_description_path
      assert_select "form > fieldset > div > div.col-sm-10 > div > input[name=avatar_action][checked]", false
      assert_select "form > fieldset > div > div.col-sm-10 > div > div.form-check > input[name=avatar_action][checked]", false

      # Updating social links should work
      put profile_description_path, :params => { :user => { :description => user.description, :social_links_attributes => [{ :url => "https://test.com/test" }] } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_select ".alert-success", /^Profile updated./
      assert_select "a", "test.com/test"

      # Updating the company name should work
      put profile_description_path, :params => { :user => { :company => "new company", :description => user.description } }
      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_select ".alert-success", /^Profile updated./
      assert_select "dd", "new company"
    end

    def test_update_empty_social_link
      user = create(:user)
      session_for(user)

      put profile_description_path, :params => { :user => { :description => user.description, :social_links_attributes => [{ :url => "" }] } }

      assert_response :success
      assert_template :show
      assert_dom ".alert-danger", :text => "Couldn't update profile."
    end
  end
end
