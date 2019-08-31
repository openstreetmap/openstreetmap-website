require "application_system_test_case"

class ReportUserTest < ApplicationSystemTestCase
  def test_no_link_when_not_logged_in
    note = create(:note_with_comments)
    visit browse_note_path(note)
    assert page.has_content?(note.comments.first.body)

    assert_not page.has_content?(I18n.t("users.show.report"))
  end

  def test_can_report_user
    user = create(:user)
    sign_in_as(create(:user))
    visit user_path(user)

    click_on I18n.t("users.show.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.user.vandal_label")
    fill_in "report_details", :with => "This user is a vandal"
    assert_difference "Issue.count", 1 do
      click_on "Create Report"
    end

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal user, Issue.last.reportable
    assert_equal "moderator", Issue.last.assigned_role
  end

  def test_it_promotes_issues
    user = create(:user)
    sign_in_as(create(:user))
    visit user_path(user)

    click_on I18n.t("users.show.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.user.vandal_label")
    fill_in "report_details", :with => "This user is a vandal"
    assert_difference "Issue.count", 1 do
      click_on "Create Report"
    end

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal user, Issue.last.reportable
    assert_equal "moderator", Issue.last.assigned_role

    visit user_path(user)

    click_on I18n.t("users.show.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.user.spam_label")
    fill_in "report_details", :with => "This user is a spammer"
    assert_no_difference "Issue.count" do
      click_on "Create Report"
    end

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal user, Issue.last.reportable
    assert_equal "administrator", Issue.last.assigned_role
  end
end
