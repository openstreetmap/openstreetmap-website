# frozen_string_literal: true

require "application_system_test_case"

class UserLoginTest < ApplicationSystemTestCase
  test "Warn on login page when already logged in" do
    user1 = create(:user, :display_name => "First User")
    user2 = create(:user, :display_name => "Second User")
    sign_in_as(user1)

    visit login_path

    assert_button "First User"
    within_content_body do
      assert_text "logged in as First User"
      assert_no_link "Visit referring page"
    end

    fill_in "username", :with => user2.email
    fill_in "password", :with => "s3cr3t"
    click_on "Log in"

    assert_button "Second User"
  end

  test "Warn on login page when already logged in with referer link" do
    user1 = create(:user, :display_name => "First User")
    sign_in_as(user1)

    visit login_path(:referer => copyright_path, :anchor => "trademarks")

    assert_button "First User"
    within_content_body do
      assert_text "logged in as First User"
      assert_link "Visit referring page"

      click_on "Visit referring page"
    end

    assert_current_path copyright_path
    assert_equal "#trademarks", execute_script("return location.hash")
  end

  test "Only show safe referer links inside warnings" do
    user1 = create(:user, :display_name => "First User")
    sign_in_as(user1)

    visit login_path(:referer => "https://example.com/")

    assert_button "First User"
    within_content_body do
      assert_text "logged in as First User"
      assert_no_link "Visit referring page"
    end
  end
end
