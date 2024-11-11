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
    create(:friendship, :befriender => user, :befriendee => friend_user)
    create(:changeset, :user => friend_user)
    sign_in_as(user)

    visit dashboard_path
    assert_no_text "You have not followed any user yet."

    friends_heading = find :element, "h2", :text => "Followings"
    others_heading = find :element, "h2", :text => "Other nearby users"

    assert_link friend_user.display_name, :below => friends_heading, :above => others_heading
  end
end
