require "application_system_test_case"

class ReportNoteTest < ApplicationSystemTestCase
  def test_no_link_when_not_logged_in
    note = create(:note_with_comments)
    visit browse_note_path(note)
    assert page.has_content?(note.comments.first.body)

    assert !page.has_content?(I18n.t("browse.note.report"))
  end

  def test_can_report_anonymous_notes
    note = create(:note_with_comments)
    sign_in_as(create(:user))
    visit browse_note_path(note)

    click_on I18n.t("browse.note.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.note.spam")
    fill_in "report_details", :with => "This is spam"
    click_on "Create Report"

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal 1, Issue.count
    assert Issue.last.reportable == note
  end

  def test_can_report_notes_with_author
    note = create(:note_comment, :author => create(:user)).note
    sign_in_as(create(:user))
    visit browse_note_path(note)

    click_on I18n.t("browse.note.report")
    assert page.has_content? "Report"
    assert page.has_content? I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.note.spam")
    fill_in "report_details", :with => "This is spam"
    click_on "Create Report"

    assert page.has_content? "Your report has been registered sucessfully"

    assert_equal 1, Issue.count
    assert Issue.last.reportable == note
  end
end
