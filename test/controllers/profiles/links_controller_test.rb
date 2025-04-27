# frozen_string_literal: true

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

    def test_update
      user = create(:user)
      session_for(user)

      put profile_links_path, :params => { :user => { :social_links_attributes => [{ :url => "https://test.com/test" }] } }

      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Profile links updated."
      assert_dom "a[href*='test.com/test'] span", "test.com/test"
    end

    def test_update_empty_social_link
      user = create(:user)
      session_for(user)

      put profile_links_path, :params => { :user => { :social_links_attributes => [{ :url => "" }] } }

      assert_response :success
      assert_template :show
      assert_dom ".alert-danger", :text => "Couldn't update profile links."
    end
  end
end
