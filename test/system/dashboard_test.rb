require "application_system_test_case"

class DashboardSystemTest < ApplicationSystemTestCase
  test "show no users if have no followings" do
    user = create(:user)
    sign_in_as(user)

    visit dashboard_path
    assert_text "You have not followed any user yet."
  end

  test "show users if have friends" do
    user = create(:user, :home_lon => 1.1, :home_lat => 1.1)
    friend_user = create(:user, :home_lon => 1.2, :home_lat => 1.2)
    create(:follow, :follower => user, :following => friend_user)
    create(:changeset, :user => friend_user)
    sign_in_as(user)

    visit dashboard_path
    assert_no_text "You have not followed any user yet."

    friends_heading = find :element, "h2", :text => "Followings"
    others_heading = find :element, "h2", :text => "Other nearby users"

    assert_link friend_user.display_name, :below => friends_heading, :above => others_heading
  end

  test "show nearby users with ability to follow" do
    user = create(:user, :home_lon => 1.1, :home_lat => 1.1)
    nearby_user = create(:user, :home_lon => 1.2, :home_lat => 1.2)
    sign_in_as(user)

    visit dashboard_path

    within_content_body do
      others_nearby_heading = find :element, "h2", :text => "Other nearby users"

      assert_no_text "There are no other users who admit to mapping nearby yet"
      assert_link nearby_user.display_name, :below => others_nearby_heading
      assert_link "Follow", :below => others_nearby_heading

      click_on "Follow"

      followings_heading = find :element, "h2", :text => "Followings"
      others_nearby_heading = find :element, "h2", :text => "Other nearby users"

      assert_text "There are no other users who admit to mapping nearby yet"
      assert_link nearby_user.display_name, :below => followings_heading, :above => others_nearby_heading
      assert_link "Unfollow", :below => followings_heading, :above => others_nearby_heading
    end
  end
end
