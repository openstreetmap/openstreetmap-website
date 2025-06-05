require "application_system_test_case"

class ProfileLocationChangeTest < ApplicationSystemTestCase
  test "can't change location when unauthorized" do
    user = create(:user)

    visit user_path(user)

    within_content_heading do
      assert_no_link "Edit Location"
    end
  end

  test "can't change location of another user" do
    user = create(:user)
    another_user = create(:user)

    sign_in_as(user)
    visit user_path(another_user)

    within_content_heading do
      assert_no_link "Edit Location"
    end
  end

  test "can change location" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_heading do
      assert_text "No home location specified"

      click_on "Edit Location"
    end

    within_content_body do
      fill_in "Home location name", :with => "Test Place"
      click_on "Update Profile"
    end

    assert_text "Profile location updated."

    within_content_heading do
      assert_text "Home location Test Place"

      click_on "Edit Location"
    end

    within_content_body do
      fill_in "Home location name", :with => "New Test Place"
      click_on "Update Profile"
    end

    assert_text "Profile location updated."

    within_content_heading do
      assert_text "Home location New Test Place"
    end
  end
end
