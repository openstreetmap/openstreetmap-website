require "application_system_test_case"

class FollowsTest < ApplicationSystemTestCase
  test "show message when max frienships limit is exceeded" do
    following = create(:user)

    sign_in_as create(:user)

    with_settings(:max_follows_per_hour => 0) do
      visit user_path(following)
      assert_link "Follow"

      click_on "Follow"
      assert_text "You have followed a lot of users recently"
      assert_link "Follow"
    end
  end
end
