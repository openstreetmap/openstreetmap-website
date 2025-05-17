require "test_helper"

module Preferences
  class BasicPreferencesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/preferences/basic", :method => :get },
        { :controller => "preferences/basic_preferences", :action => "show" }
      )
      assert_routing(
        { :path => "/preferences/basic", :method => :put },
        { :controller => "preferences/basic_preferences", :action => "update" }
      )

      get "/preferences"
      assert_redirected_to "/preferences/basic"

      get "/preferences/edit"
      assert_redirected_to "/preferences/basic"
    end

    def test_update_preferred_editor
      user = create(:user, :languages => [])
      user.preferences.create(:k => "site.color_scheme", :v => "light")
      user.preferences.create(:k => "map.color_scheme", :v => "light")
      session_for(user)

      # Changing to a invalid editor should fail
      put basic_preferences_path, :params => { :user => { :preferred_editor => "unknown" } }
      assert_response :success
      assert_template :show
      assert_select ".alert-success", false
      assert_select ".alert-danger", true
      user.reload
      assert_nil user.preferred_editor
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v

      # Changing to a valid editor should work
      put basic_preferences_path, :params => { :user => { :preferred_editor => "id" } }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      user.reload
      assert_equal "id", user.preferred_editor
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v

      # Changing to the default editor should work
      put basic_preferences_path, :params => { :user => { :preferred_editor => "default" } }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      user.reload
      assert_nil user.preferred_editor
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v
    end

    def test_update_preferred_site_color_scheme
      user = create(:user, :languages => [])
      session_for(user)
      assert_nil user.preferences.find_by(:k => "site.color_scheme")

      # Changing when previously not defined
      put basic_preferences_path, :params => { :user => user.attributes, :site_color_scheme => "light" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v

      # Changing when previously defined
      put basic_preferences_path, :params => { :user => user.attributes, :site_color_scheme => "auto" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "auto", user.preferences.find_by(:k => "site.color_scheme")&.v
    end

    def test_update_preferred_map_color_scheme
      user = create(:user, :languages => [])
      session_for(user)
      assert_nil user.preferences.find_by(:k => "map.color_scheme")

      # Changing when previously not defined
      put basic_preferences_path, :params => { :user => user.attributes, :map_color_scheme => "light" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v

      # Changing when previously defined
      put basic_preferences_path, :params => { :user => user.attributes, :map_color_scheme => "auto" }
      assert_redirected_to basic_preferences_path
      follow_redirect!
      assert_template :show
      assert_select ".alert-success", /^Preferences updated/
      assert_equal "auto", user.preferences.find_by(:k => "map.color_scheme")&.v
    end
  end
end
