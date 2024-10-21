require "application_system_test_case"

class UserLogoutTest < ApplicationSystemTestCase
  test "Sign out via link" do
    user = create(:user)
    sign_in_as(user)
    assert_no_content "Log In"

    click_on user.display_name
    click_on "Log Out"
    assert_content "Log In"
  end

  test "Sign out via link with referer" do
    user = create(:user)
    sign_in_as(user)
    visit traces_path
    assert_no_content "Log In"

    click_on user.display_name
    click_on "Log Out"
    assert_content "Log In"
    assert_content "Public GPS Traces"
  end

  test "Sign out via fallback page" do
    sign_in_as(create(:user))
    assert_no_content "Log In"

    visit logout_path
    assert_content "Logout from OpenStreetMap"

    click_on "Logout"
    assert_content "Log In"
  end

  test "Sign out via fallback page with referer" do
    sign_in_as(create(:user))
    assert_no_content "Log In"

    visit logout_path(:referer => "/traces")
    assert_content "Logout from OpenStreetMap"

    click_on "Logout"
    assert_content "Log In"
    assert_content "Public GPS Traces"
  end

  test "Sign out after navigating with Turbo pagination" do
    saved_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    create(:language, :code => "en")
    create(:diary_entry, :title => "First Diary Entry")
    create_list(:diary_entry, 20) # rubocop:disable FactoryBot/ExcessiveCreateList
    user = create(:user)
    sign_in_as user

    visit diary_entries_path
    assert_no_link "Log In"

    click_on "Older Entries"
    assert_link "First Diary Entry"

    click_on user.display_name
    click_on "Log Out"
    assert_link "Log In"
  ensure
    ActionController::Base.allow_forgery_protection = saved_allow_forgery_protection
  end
end
