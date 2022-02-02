require "application_system_test_case"

class UserStatusChangeTest < ApplicationSystemTestCase
  def setup
    admin = create(:administrator_user)
    sign_in_as(admin)
  end

  test "Admin can unsuspend a user" do
    user = create(:user, :suspended)
    visit user_path(user)
    accept_confirm do
      click_on "Unsuspend"
    end

    assert_no_content "Unsuspend"
    user.reload
    assert_equal "active", user.status
  end

  test "Admin can confirm a user" do
    user = create(:user, :suspended)
    visit user_path(user)
    accept_confirm do
      click_on "Confirm"
    end

    assert_no_content "Unsuspend"
    user.reload
    assert_equal "confirmed", user.status
  end
end
