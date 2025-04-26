require "application_system_test_case"

class UserLoginTest < ApplicationSystemTestCase
  test "Warn on login page when already logged in" do
    user1 = create(:user, :display_name => "First User")
    user2 = create(:user, :display_name => "Second User")
    sign_in_as(user1)

    visit login_path

    assert_button "First User"
    within_content_body do
      assert_text "logged in as First User"
    end

    fill_in "username", :with => user2.email
    fill_in "password", :with => "test"
    click_on "Log in"

    assert_button "Second User"
  end

  test "Show OpenID form when OpenID provider button is clicked" do
    visit login_path

    within_content_body do
      assert_no_field "OpenID URL"
      assert_no_button "Continue"

      click_on "Log in with OpenID"

      assert_field "OpenID URL"
      assert_button "Continue"
    end
  end
end
