# frozen_string_literal: true

require "application_system_test_case"

class ProfileImageChangeTest < ApplicationSystemTestCase
  test "can't change image when unauthorized" do
    user = create(:user)

    visit user_path(user)

    within_content_heading do
      assert_no_link "Change Image"
    end

    within_content_body do
      assert_no_button "Edit Profile Details"
      assert_no_link "Change Image"
    end
  end

  test "can't change image of another user" do
    user = create(:user)
    another_user = create(:user)

    sign_in_as(user)
    visit user_path(another_user)

    within_content_heading do
      assert_no_link "Change Image"
    end

    within_content_body do
      assert_no_button "Edit Profile Details"
      assert_no_link "Change Image"
    end
  end

  test "can add and remove image" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Change Image"
      assert_unchecked_field "Add an image"
      assert_no_field "Keep the current image"
      assert_no_field "Remove the current image"
      assert_no_field "Replace the current image"

      attach_file "Avatar", "test/gpx/fixtures/a.gif"

      assert_checked_field "Add an image"

      click_on "Update Profile"
    end

    assert_text "Profile image updated."

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Change Image"
      assert_no_field "Add an image"
      assert_checked_field "Keep the current image"
      assert_unchecked_field "Remove the current image"
      assert_unchecked_field "Replace the current image"

      choose "Remove the current image"
      click_on "Update Profile"
    end

    assert_text "Profile image updated."

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Change Image"
      assert_unchecked_field "Add an image"
      assert_no_field "Keep the current image"
      assert_no_field "Remove the current image"
      assert_no_field "Replace the current image"
    end
  end

  test "can add image by clicking the placeholder image" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_heading do
      click_on "Change Image"
    end

    within_content_body do
      assert_unchecked_field "Add an image"
      assert_no_field "Keep the current image"
      assert_no_field "Remove the current image"
      assert_no_field "Replace the current image"

      attach_file "Avatar", "test/gpx/fixtures/a.gif"

      assert_checked_field "Add an image"

      click_on "Update Profile"
    end

    assert_text "Profile image updated."

    within_content_heading do
      click_on "Change Image"
    end

    within_content_body do
      assert_no_field "Add an image"
      assert_checked_field "Keep the current image"
      assert_unchecked_field "Remove the current image"
      assert_unchecked_field "Replace the current image"
    end
  end
end
