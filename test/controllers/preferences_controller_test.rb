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
    session_for(user)

    # Changing to a invalid editor should fail
    user.preferred_editor = "unknown"
    put preferences_path, :params => { :user => user.attributes }
    assert_response :success
    assert_template :edit
    assert_select ".notice", false
    assert_select ".error", true
    assert_select "form > div > select#user_preferred_editor > option[selected]", false

    # Changing to a valid editor should work
    user.preferred_editor = "id"
    put preferences_path, :params => { :user => user.attributes }
    assert_response :redirect
    assert_redirected_to preferences_path
    follow_redirect!
    assert_template :show
    assert_select ".notice", /^Preferences updated/
    assert_select "dd", "iD (in-browser editor)"

    # Changing to the default editor should work
    user.preferred_editor = "default"
    put preferences_path, :params => { :user => user.attributes }
    assert_response :redirect
    assert_redirected_to preferences_path
    follow_redirect!
    assert_template :show
    assert_select ".notice", /^Preferences updated/
    assert_select "dd", "Default (currently iD)"
  end
end
