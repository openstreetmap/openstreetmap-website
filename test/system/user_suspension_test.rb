require "application_system_test_case"

class UserSuspensionTest < ApplicationSystemTestCase
  test "User shown a message when suspended mid-session" do
    user = create(:user)
    sign_in_as(user)
    visit edit_account_path
    assert_content "My Settings"

    user.suspend!

    visit edit_account_path
    assert_content "This decision will be reviewed by an administrator shortly"
  end
end
