require "application_system_test_case"

class ReportMicrocosmTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    @microcosm = create(:microcosm)
  end

  def test_no_link_when_not_logged_in
    visit microcosm_path(@microcosm)
    assert page.has_content?(@microcosm.name)

    assert_not page.has_content?(I18n.t("microcosms.show.report"))
  end

  def test_it_works
    sign_in_as(create(:user))
    visit microcosm_path(@microcosm)
    assert page.has_content? @microcosm.name

    click_on I18n.t("microcosms.show.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.microcosm.spam_label")
    fill_in "report_details", :with => "This comment is spam"
    assert_difference "Issue.count", 1 do
      click_on "Create Report"
    end

    assert page.has_content? "Your report has been registered successfully"
  end
end
