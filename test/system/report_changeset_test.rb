require "application_system_test_case"

class ReportChangesetTest < ApplicationSystemTestCase
  def setup
    @creator = create(:user)
    @changeset = create(:changeset, :user => @creator)
    create(:changeset_tag, :changeset => @changeset, :k => "comment", :v => "changeset-comment-test-value")
  end

  def test_no_link_when_not_logged_in
    visit changeset_path(@changeset)
    assert_content "changeset-comment-test-value"

    assert_no_content I18n.t("changesets.show.report")
  end

  def test_no_link_for_own_changeset
    sign_in_as(@creator)
    visit changeset_path(@changeset)
    assert_content "changeset-comment-test-value"

    assert_no_content I18n.t("changesets.show.report")
  end

  def test_it_works
    sign_in_as(create(:user))
    visit changeset_path(@changeset)
    assert_content "changeset-comment-test-value"

    click_on I18n.t("changesets.show.report")
    assert_content "Report"
    assert_content I18n.t("reports.new.disclaimer.intro")

    choose I18n.t("reports.new.categories.changeset.spam_label")
    fill_in "report_details", :with => "This is advertising"
    assert_difference "Issue.count", 1 do
      click_on "Create Report"
    end

    assert_content "Your report has been registered successfully"

    assert_equal @changeset, Issue.last.reportable
    assert_equal "moderator", Issue.last.assigned_role

    sign_in_as(create(:moderator_user))
    visit issues_path(:status => "open")
    assert_link :href => changeset_url(@changeset)

    click_on "1 Report"
    assert_content "This is advertising"
  end
end
