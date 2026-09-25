# frozen_string_literal: true

require "application_system_test_case"

class ProfileLinksChangeTest < ApplicationSystemTestCase
  test "can't change description when unauthorized" do
    user = create(:user)

    visit user_path(user)

    within_content_body do
      assert_no_link "Edit Description"
    end
  end

  test "can't change description of another user" do
    user = create(:user)
    another_user = create(:user)

    sign_in_as(user)
    visit user_path(another_user)

    within_content_body do
      assert_no_link "Edit Description"
    end
  end

  test "can change description" do
    user = create(:user)
    check_description_change(user)
  end

  test "can change description when have a description" do
    user = create(:user, :description => "My old profile description")
    check_description_change(user)
  end

  test "can change description when have a link" do
    user = create(:user)
    create(:social_link, :user => user)
    check_description_change(user)
  end

  test "can change description when have a description and a link" do
    user = create(:user, :description => "My old profile description")
    create(:social_link, :user => user)
    check_description_change(user)
  end

  private

  def check_description_change(user)
    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Description"
      fill_in "Profile Description", :with => "This is my updated OSM profile!"
      click_on "Update Profile"
    end

    assert_text "Profile description updated."

    within_content_body do
      assert_text "This is my updated OSM profile!"
    end
  end
end
