require "application_system_test_case"

class FriendshipsTest < ApplicationSystemTestCase
  test "show message when max frienships limit is exceeded" do
    befriendee = create(:user)

    sign_in_as create(:user)

    with_settings(:max_friends_per_hour => 0) do
      visit user_path(befriendee)
      assert_link "Add Friend"

      click_on "Add Friend"
      assert_text "You have friended a lot of users recently"
      assert_link "Add Friend"
    end
  end
end
