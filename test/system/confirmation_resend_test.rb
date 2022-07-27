require "application_system_test_case"

class ConfirmationResendSystemTest < ApplicationSystemTestCase
  def setup
    @user = build(:user)
    visit user_new_path

    fill_in "Email", :with => @user.email
    fill_in "Email Confirmation", :with => @user.email
    fill_in "Display Name", :with => @user.display_name
    fill_in "Password", :with => "testtest"
    fill_in "Confirm Password", :with => "testtest"
    click_button "Sign Up"

    check "I have read and agree to the above contributor terms"
    check "I have read and agree to the Terms of Use"
    click_button "Continue"
  end

  test "flash message should not contain raw html" do
    visit user_confirm_resend_path(@user)

    assert_content "sent a new confirmation"
    assert_no_content "<p>"
  end
end
