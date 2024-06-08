require "application_system_test_case"

class ReportCommunityTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    @community = create(:community)
  end

  def test_no_link_when_not_logged_in
    visit community_path(@community)
    assert page.has_content?(@community.name)

    assert_not page.has_content?(I18n.t("communities.show.report"))
  end

  def test_it_works
    sign_in_as(create(:user))
    visit community_path(@community)
    assert page.has_content? @community.name

    click_on I18n.t("communities.show.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.community.spam_label")
    fill_in "report_details", :with => "This comment is spam"
    assert_difference "Issue.count", 1 do
      click_on "Create Report"
    end

    assert page.has_content? "Your report has been registered successfully"
  end
end
