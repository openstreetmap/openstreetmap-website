require "application_system_test_case"

class UserSignupTest < ApplicationSystemTestCase
  test "Sign up from login page" do
    visit login_path

    click_link "Register now"

    assert_content "Confirm Password"
  end

  test "externally redirect when contributor terms declined" do
    user = build(:user)

    visit root_path
    click_link "Sign Up"
    fill_in "Email", :with => user.email
    fill_in "Email Confirmation", :with => user.email
    fill_in "Display Name", :with => user.display_name
    fill_in "Password", :with => "testtest"
    fill_in "Confirm Password", :with => "testtest"
    click_button "Sign Up"

    assert_content "Contributor terms"
    click_button "Cancel"

    assert_current_path "https://wiki.openstreetmap.org/wiki/Contributor_Terms_Declined"
  end
end
