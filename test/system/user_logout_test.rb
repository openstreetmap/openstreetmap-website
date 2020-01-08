require "application_system_test_case"

class UserLogoutTest < ApplicationSystemTestCase
  test "Sign out via link" do
    user = create(:user)
    sign_in_as(user)
    assert_not page.has_content? "Log In"

    click_on user.display_name
    click_on "Log Out"
    assert page.has_content? "Log In"
  end

  test "Sign out via link with referer" do
    user = create(:user)
    sign_in_as(user)
    visit traces_path
    assert_not page.has_content? "Log In"

    click_on user.display_name
    click_on "Log Out"
    assert page.has_content? "Log In"
    assert page.has_content? "Public GPS traces"
  end

  test "Sign out via fallback page" do
    sign_in_as(create(:user))
    assert_not page.has_content? "Log In"

    visit logout_path
    assert page.has_content? "Logout from OpenStreetMap"

    click_button "Logout"
    assert page.has_content? "Log In"
  end

  test "Sign out via fallback page with referer" do
    sign_in_as(create(:user))
    assert_not page.has_content? "Log In"

    visit logout_path(:referer => "/traces")
    assert page.has_content? "Logout from OpenStreetMap"

    click_button "Logout"
    assert page.has_content? "Log In"
    assert page.has_content? "Public GPS traces"
  end
end
