# frozen_string_literal: true

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

    def test_update
      user = create(:user)
      session_for(user)

      put profile_location_path, :params => { :user => { :home_lat => 60, :home_lon => 30, :home_location_name => "Лисий Нос" } }

      assert_redirected_to user_path(user)
      follow_redirect!
      assert_response :success
      assert_template :show
      assert_dom ".alert-success", :text => "Profile location updated."

      user.reload
      assert_equal 60, user.home_lat
      assert_equal 30, user.home_lon
      assert_equal "Лисий Нос", user.home_location_name
      assert_equal 3543348019, user.home_tile
    end

    def test_update_lat_out_of_range
      user = create(:user)
      session_for(user)

      put profile_location_path, :params => { :user => { :home_lat => 91, :home_lon => 30, :home_location_name => "Лисий Нос" } }

      assert_response :success
      assert_template :show
      assert_dom ".alert-danger", :text => "Couldn't update profile location."

      user.reload
      assert_nil user.home_lat
      assert_nil user.home_lon
      assert_nil user.home_location_name
      assert_nil user.home_tile
    end

    def test_update_lon_out_of_range
      user = create(:user)
      session_for(user)

      put profile_location_path, :params => { :user => { :home_lat => 60, :home_lon => 181, :home_location_name => "Лисий Нос" } }

      assert_response :success
      assert_template :show
      assert_dom ".alert-danger", :text => "Couldn't update profile location."

      user.reload
      assert_nil user.home_lat
      assert_nil user.home_lon
      assert_nil user.home_location_name
      assert_nil user.home_tile
    end
  end
end
