require "application_system_test_case"

class UserCompanyTest < ApplicationSystemTestCase
  test "User can change company" do
    user = create(:user)
    sign_in_as(user)
    company = "Test Company"

    visit user_path(user)

    within_content_heading do
      assert_no_selector ".bi.bi-suitcase-lg-fill"
    end

    visit profile_path

    assert_text I18n.t("activerecord.attributes.user.company")

    fill_in "Company", :with => company
    click_on I18n.t("profiles.show.save")

    assert_text I18n.t("profiles.update.success")
    within_content_heading do
      assert_text company
    end
  end
end
