# frozen_string_literal: true

require "application_system_test_case"

class ProfileCompanyChangeTest < ApplicationSystemTestCase
  test "can't change company when unauthorized" do
    user = create(:user)

    visit user_path(user)

    within_content_body do
      assert_no_button "Edit Profile Details"
      assert_no_link "Edit Company"
    end
  end

  test "can't change company of another user" do
    user = create(:user)
    another_user = create(:user)

    sign_in_as(user)
    visit user_path(another_user)

    within_content_body do
      assert_no_button "Edit Profile Details"
      assert_no_link "Edit Company"
    end
  end

  test "can change company" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Edit Company"
      fill_in "Company", :with => "Test Co."
      click_on "Update Profile"
    end

    assert_text "Profile company updated."

    within_content_body do
      assert_text :all, "Company Test Co."

      click_on "Edit Profile Details"
      click_on "Edit Company"
      fill_in "Company", :with => "Test More Co."
      click_on "Update Profile"
    end

    assert_text "Profile company updated."

    within_content_body do
      assert_text :all, "Company Test More Co."
    end
  end
end
