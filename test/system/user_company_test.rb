require "application_system_test_case"

class UserCompanyTest < ApplicationSystemTestCase
  test "User can change company" do
    user = create(:user)
    sign_in_as(user)

    visit user_path(user)

    within_content_body do
      assert_no_text :all, "Company"
    end

    visit profile_description_path

    within_content_body do
      fill_in "Company", :with => "Test Co."
      click_on "Update Profile"
    end

    assert_text "Profile updated."

    within_content_body do
      assert_text :all, "Company Test Co."
    end
  end
end
