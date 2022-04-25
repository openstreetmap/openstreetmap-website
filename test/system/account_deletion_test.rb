require "application_system_test_case"

class AccountDeletionTest < ApplicationSystemTestCase
  def setup
    @user = create(:user, :display_name => "test user")
    sign_in_as(@user)
  end

  test "the status is deleted and the personal data removed" do
    visit edit_account_path

    click_on "Delete Account..."
    accept_confirm do
      click_on "Delete Account"
    end

    assert_current_path root_path
    @user.reload
    assert_equal "deleted", @user.status
    assert_equal "user_#{@user.id}", @user.display_name
  end

  test "the user is signed out after deletion" do
    visit edit_account_path

    click_on "Delete Account..."
    accept_confirm do
      click_on "Delete Account"
    end

    assert_content "Log In"
  end

  test "the user is shown a confirmation flash message" do
    visit edit_account_path

    click_on "Delete Account..."
    accept_confirm do
      click_on "Delete Account"
    end

    assert_content "Account Deleted"
  end
end
