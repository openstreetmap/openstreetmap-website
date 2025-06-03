require "application_system_test_case"

class ProfileCompanyChangeTest < ApplicationSystemTestCase
  test "User can change company" do
    user = create(:user)
    sign_in_as(user)
    company = "Test Company"

    visit user_path(user)

    within_content_heading do
      assert_no_selector ".bi.bi-suitcase-lg-fill"
    end

    visit profile_company_path

    within_content_body do
      fill_in "Company", :with => company
      click_on "Update Profile"
    end

    assert_text "Profile company updated."
    within_content_heading do
      assert_text company
    end
  end
end
