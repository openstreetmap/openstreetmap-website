require "application_system_test_case"

class UserLoginTest < ApplicationSystemTestCase
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
