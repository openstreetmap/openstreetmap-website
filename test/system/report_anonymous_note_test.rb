require "application_system_test_case"

class ReportAnonymousNoteTest < ApplicationSystemTestCase
  def test_no_flag_when_not_logged_in
    note = create(:note_with_comments)
    visit browse_note_path(note)
    assert page.has_content?(note.comments.first.body)

    assert !page.has_content?("\u2690")
  end

  def test_can_report_anonymous_notes
    note = create(:note_with_comments)
    sign_in_as(create(:user))
    visit browse_note_path(note)

    click_on "\u2690"
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("issues.new.disclaimer.intro")

    choose I18n.t("reports.categories.Note.spam")
    fill_in "report_details", :with => "This is spam"
    click_on "Create Report"

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal 1, Issue.count
    assert Issue.last.reportable == note
  end
end
