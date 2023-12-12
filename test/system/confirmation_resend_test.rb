require "application_system_test_case"

class ConfirmationResendSystemTest < ApplicationSystemTestCase
  def setup
    @user = build(:user)
    visit user_new_path

    within ".new_user" do
      fill_in "Email", :with => @user.email
      fill_in "Display Name", :with => @user.display_name
      fill_in "Password", :with => "testtest"
      fill_in "Confirm Password", :with => "testtest"
      click_on "Sign Up"
    end
  end

  test "flash message should not contain raw html" do
    visit user_confirm_resend_path(@user)

    assert_content "sent a new confirmation"
    assert_no_content "<p>"
  end
end
