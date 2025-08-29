# frozen_string_literal: true

require "application_system_test_case"

class ProfileLinksChangeTest < ApplicationSystemTestCase
  test "can't change links when unauthorized" do
    user = create(:user)

    visit user_path(user)

    within_content_body do
      assert_no_button "Edit Profile Details"
      assert_no_link "Edit Links"
    end
  end

  test "can't change links of another user" do
    user = create(:user)
    another_user = create(:user)

    sign_in_as(user)
    visit user_path(another_user)

    within_content_body do
      assert_no_button "Edit Profile Details"
      assert_no_link "Edit Links"
    end
  end

  test "can add and remove social link without submitting" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Edit Links"

      assert_no_field "Social Profile Link 1"

      click_on "Add Social Link"

      assert_field "Social Profile Link 1"

      click_on "Remove Social Profile Link 1"

      assert_no_field "Social Profile Link 1"
    end
  end

  test "can add and remove social links" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Edit Links"

      assert_no_field "Social Profile Link 1"

      click_on "Add Social Link"
      fill_in "Social Profile Link 1", :with => "https://example.com/user/fred"
      click_on "Update Profile"

      assert_link "example.com/user/fred"

      click_on "Edit Profile Details"
      click_on "Edit Links"
      click_on "Remove Social Profile Link 1"

      assert_no_field "Social Profile Link 1"

      click_on "Update Profile"

      assert_no_link "example.com/user/fred"
    end
  end

  test "can control social links using keyboard without submitting" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Edit Links"
      click_on "Add Social Link"

      assert_field "Social Profile Link 1"

      send_keys :tab, :enter

      assert_no_field "Social Profile Link 1"
    end
  end

  test "can control social links using keyboard" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Edit Links"
      click_on "Add Social Link"
      send_keys "https://example.com/user/typed"
      click_on "Update Profile"

      assert_link "example.com/user/typed"

      click_on "Edit Profile Details"
      click_on "Edit Links"
      find_field("Social Profile Link 1").click
      send_keys :tab, :enter

      assert_no_field "Social Profile Link 1"

      click_on "Update Profile"

      assert_no_link "example.com/user/typed"
    end
  end

  test "can add and remove multiple links" do
    user = create(:user)

    sign_in_as(user)
    visit user_path(user)

    within_content_body do
      click_on "Edit Profile Details"
      click_on "Edit Links"
      click_on "Add Social Link"
      fill_in "Social Profile Link 1", :with => "https://example.com/a"
      click_on "Add Social Link"
      fill_in "Social Profile Link 2", :with => "https://example.com/b"
      click_on "Add Social Link"
      fill_in "Social Profile Link 3", :with => "https://example.com/c"
      click_on "Update Profile"

      assert_link "example.com/a"
      assert_link "example.com/b"
      assert_link "example.com/c"

      click_on "Edit Profile Details"
      click_on "Edit Links"
      assert_field "Social Profile Link 1", :with => "https://example.com/a"
      assert_field "Social Profile Link 2", :with => "https://example.com/b"
      assert_field "Social Profile Link 3", :with => "https://example.com/c"

      click_on "Remove Social Profile Link 2"

      assert_field "Social Profile Link 1", :with => "https://example.com/a"
      assert_field "Social Profile Link 2", :with => "https://example.com/c"

      click_on "Add Social Link"
      fill_in "Social Profile Link 3", :with => "https://example.com/d"
      click_on "Update Profile"

      assert_link "example.com/a"
      assert_no_link "example.com/b"
      assert_link "example.com/c"
      assert_link "example.com/d"
    end
  end
end
