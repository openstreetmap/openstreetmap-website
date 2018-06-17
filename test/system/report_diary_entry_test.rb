require "application_system_test_case"

class ReportDiaryEntryTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    @diary_entry = create(:diary_entry)
  end

  def test_no_link_when_not_logged_in
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content?(@diary_entry.title)

    assert_not page.has_content?(I18n.t("diary_entry.diary_entry.report"))
  end

  def test_it_works
    sign_in_as(create(:user))
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content? @diary_entry.title

    click_on I18n.t("diary_entry.diary_entry.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.diary_entry.spam_label")
    fill_in "report_details", :with => "This is advertising"
    assert_difference "Issue.count", 1 do
      click_on "Create Report"
    end

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal @diary_entry, Issue.last.reportable
    assert_equal "administrator", Issue.last.assigned_role
  end

  def test_it_reopens_issue
    issue = create(:issue, :reportable => @diary_entry)
    issue.resolve!

    sign_in_as(create(:user))
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content? @diary_entry.title

    click_on I18n.t("diary_entry.diary_entry.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.diary_entry.spam_label")
    fill_in "report_details", :with => "This is advertising"
    assert_no_difference "Issue.count" do
      click_on "Create Report"
    end

    issue.reload
    assert_not issue.resolved?
    assert issue.open?
  end

  def test_missing_report_params
    sign_in_as(create(:user))
    visit new_report_path
    assert page.has_content? I18n.t("reports.new.missing_params")
  end
end
