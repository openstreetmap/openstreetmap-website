require "application_system_test_case"

class ReportDiaryEntryTest < ApplicationSystemTestCase
  def setup
    create(:language, :code => "en")
    @diary_entry = create(:diary_entry)
  end

  def test_no_flag_when_not_logged_in
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content?(@diary_entry.title)

    assert !page.has_content?("\u2690")
  end

  def test_it_works
    sign_in_as(create(:user))
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content? @diary_entry.title

    click_on "\u2690"
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("issues.new.disclaimer.intro")

    choose I18n.t("reports.categories.diary_entry.spam")
    fill_in "report_details", :with => "This is advertising"
    click_on "Create Report"

    assert page.has_content? "Your report has been registered sucessfully"
  end

  def test_it_reopens_issue
    issue = create(:issue, :reportable => @diary_entry)
    issue.resolve!

    sign_in_as(create(:user))
    visit diary_entry_path(@diary_entry.user.display_name, @diary_entry)
    assert page.has_content? @diary_entry.title

    click_on "\u2690"
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("issues.new.disclaimer.intro")

    choose I18n.t("reports.categories.diary_entry.spam")
    fill_in "report_details", :with => "This is advertising"
    click_on "Create Report"

    issue.reload
    assert !issue.resolved?
    assert issue.open?
  end

  def test_missing_report_params
    sign_in_as(create(:user))
    visit new_report_path
    assert page.has_content? I18n.t("reports.new.missing_params")
  end
end
