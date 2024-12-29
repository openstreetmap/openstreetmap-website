require "application_system_test_case"

class UserSignupTest < ApplicationSystemTestCase
  test "Sign up from login page" do
    visit login_path

    click_on "Sign up"

    within_content_body do
      assert_content "Confirm Password"
    end
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
