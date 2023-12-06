require "application_system_test_case"

class UserSignupTest < ApplicationSystemTestCase
  test "Sign up from login page" do
    visit login_path

    click_on "Register now"

    assert_content "Confirm Password"
  end
end
