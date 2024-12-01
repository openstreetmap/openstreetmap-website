require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/preferences", :method => :get },
      { :controller => "preferences", :action => "show" }
    )

    assert_routing(
      { :path => "/preferences/edit", :method => :get },
      { :controller => "preferences", :action => "edit" }
    )

    assert_routing(
      { :path => "/preferences", :method => :put },
      { :controller => "preferences", :action => "update" }
    )
  end

  def test_update_preferred_editor
    user = create(:user, :languages => [])
    user.preferences.create(:k => "site.color_scheme", :v => "light")
    user.preferences.create(:k => "map.color_scheme", :v => "light")
    session_for(user)

    # Changing to a invalid editor should fail
    user.preferred_editor = "unknown"
    put preferences_path, :params => { :user => user.attributes }
    assert_response :success
    assert_template :edit
    assert_select ".alert-success", false
    assert_select ".alert-danger", true
    assert_select "form > div > select#user_preferred_editor > option[selected]", false
    assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
    assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v

    # Changing to a valid editor should work
    user.preferred_editor = "id"
    put preferences_path, :params => { :user => user.attributes }
    assert_redirected_to preferences_path
    follow_redirect!
    assert_template :show
    assert_select ".alert-success", /^Preferences updated/
    assert_select "dd", "iD (in-browser editor)"
    assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
    assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v

    # Changing to the default editor should work
    user.preferred_editor = "default"
    put preferences_path, :params => { :user => user.attributes }
    assert_redirected_to preferences_path
    follow_redirect!
    assert_template :show
    assert_select ".alert-success", /^Preferences updated/
    assert_select "dd", "Default (currently iD)"
    assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v
    assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v
  end

  def test_update_preferred_site_color_scheme
    user = create(:user, :languages => [])
    session_for(user)
    assert_nil user.preferences.find_by(:k => "site.color_scheme")

    # Changing when previously not defined
    put preferences_path, :params => { :user => user.attributes, :site_color_scheme => "light" }
    assert_redirected_to preferences_path
    follow_redirect!
    assert_template :show
    assert_select ".alert-success", /^Preferences updated/
    assert_equal "light", user.preferences.find_by(:k => "site.color_scheme")&.v

    # Changing when previously defined
    put preferences_path, :params => { :user => user.attributes, :site_color_scheme => "auto" }
    assert_redirected_to preferences_path
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
    put preferences_path, :params => { :user => user.attributes, :map_color_scheme => "light" }
    assert_redirected_to preferences_path
    follow_redirect!
    assert_template :show
    assert_select ".alert-success", /^Preferences updated/
    assert_equal "light", user.preferences.find_by(:k => "map.color_scheme")&.v

    # Changing when previously defined
    put preferences_path, :params => { :user => user.attributes, :map_color_scheme => "auto" }
    assert_redirected_to preferences_path
    follow_redirect!
    assert_template :show
    assert_select ".alert-success", /^Preferences updated/
    assert_equal "auto", user.preferences.find_by(:k => "map.color_scheme")&.v
  end
end
