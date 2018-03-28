require "application_system_test_case"

class ReportUserTest < ApplicationSystemTestCase
  def test_no_link_when_not_logged_in
    note = create(:note_with_comments)
    visit browse_note_path(note)
    assert page.has_content?(note.comments.first.body)

    assert !page.has_content?(I18n.t("user.view.report"))
  end

  def test_can_report_user
    user = create(:user)
    sign_in_as(create(:user))
    visit user_path(user.display_name)

    click_on I18n.t("user.view.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("issues.new.disclaimer.intro")

    choose I18n.t("reports.categories.user.vandal")
    fill_in "report_details", :with => "This user is a vandal"
    click_on "Create Report"

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal 1, Issue.count
    assert Issue.last.reportable == user
  end
end
