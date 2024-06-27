require "application_system_test_case"

class AccountHomeTest < ApplicationSystemTestCase
  test "Go to Home Location works on map layout pages" do
    user = create(:user, :display_name => "test user", :home_lat => 60, :home_lon => 30)
    sign_in_as(user)

    visit root_path
    assert_no_selector "img.leaflet-marker-icon"

    click_on "test user"
    click_on "Go to Home Location"
    all "img.leaflet-marker-icon", :count => 1 do |marker|
      assert_equal "My home location", marker["title"]
    end

    click_on "OpenStreetMap logo"
    assert_no_selector "img.leaflet-marker-icon"
  end

  test "Go to Home Location works on non-map layout pages" do
    user = create(:user, :display_name => "test user", :home_lat => 60, :home_lon => 30)
    sign_in_as(user)

    visit about_path
    assert_no_selector "img.leaflet-marker-icon"

    click_on "test user"
    click_on "Go to Home Location"
    all "img.leaflet-marker-icon", :count => 1 do |marker|
      assert_equal "My home location", marker["title"]
    end

    click_on "OpenStreetMap logo"
    assert_no_selector "img.leaflet-marker-icon"
  end

  test "Go to Home Location is not available for users without home location" do
    user = create(:user, :display_name => "test user")
    sign_in_as(user)

    visit root_path
    assert_no_selector "img.leaflet-marker-icon"

    click_on "test user"
    assert_no_link "Go to Home Location"
  end

  test "account home page shows a warning when visited by users without home location" do
    user = create(:user, :display_name => "test user")
    sign_in_as(user)

    visit account_home_path
    assert_no_selector "img.leaflet-marker-icon"
    assert_text "Home location is not set"
  end
end
