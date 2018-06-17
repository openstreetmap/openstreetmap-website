require "application_system_test_case"

class IssuesTest < ApplicationSystemTestCase
  include IssuesHelper

  def test_view_issues_not_logged_in
    visit issues_path
    assert page.has_content?(I18n.t("user.login.title"))
  end

  def test_view_issues_normal_user
    sign_in_as(create(:user))

    visit issues_path
    assert page.has_content?(I18n.t("application.require_moderator_or_admin.not_a_moderator_or_admin"))
  end

  def test_view_no_issues
    sign_in_as(create(:moderator_user))

    visit issues_path
    assert page.has_content?(I18n.t("issues.index.issues_not_found"))
  end

  def test_view_issues
    sign_in_as(create(:moderator_user))
    issues = create_list(:issue, 3, :assigned_role => "moderator")

    visit issues_path
    assert page.has_content?(issues.first.reported_user.display_name)
  end

  def test_view_issues_with_no_reported_user
    sign_in_as(create(:moderator_user))
    anonymous_note = create(:note_with_comments)
    issue = create(:issue, :reportable => anonymous_note, :assigned_role => "moderator")

    visit issues_path
    assert page.has_content?(reportable_title(anonymous_note))

    visit issue_path(issue)
    assert page.has_content?(reportable_title(anonymous_note))
  end

  def test_search_issues_by_user
    good_user = create(:user)
    bad_user = create(:user)
    create(:issue, :reportable => bad_user, :reported_user => bad_user, :assigned_role => "administrator")

    sign_in_as(create(:administrator_user))

    # No issues against the user
    visit issues_path
    fill_in "search_by_user", :with => good_user.display_name
    click_on "Search"
    assert_not page.has_content?(I18n.t("issues.index.user_not_found"))
    assert page.has_content?(I18n.t("issues.index.issues_not_found"))

    # User doesn't exist
    visit issues_path
    fill_in "search_by_user", :with => "Nonexistant User"
    click_on "Search"
    assert page.has_content?(I18n.t("issues.index.user_not_found"))
    assert page.has_content?(I18n.t("issues.index.issues_not_found"))

    # Find Issue against bad_user
    visit issues_path
    fill_in "search_by_user", :with => bad_user.display_name
    click_on "Search"
    assert_not page.has_content?(I18n.t("issues.index.user_not_found"))
    assert_not page.has_content?(I18n.t("issues.index.issues_not_found"))
  end

  def test_commenting
    issue = create(:issue)
    sign_in_as(create(:moderator_user))

    visit issue_path(issue)

    fill_in :issue_comment_body, :with => "test comment"
    click_on "Submit"
    assert page.has_content?(I18n.t("issue_comments.create.comment_created"))
    assert page.has_content?("test comment")

    issue.reload
    assert_equal issue.comments.first.body, "test comment"
  end

  def test_reassign_issue
    issue = create(:issue)
    assert_equal "administrator", issue.assigned_role
    sign_in_as(create(:administrator_user))

    visit issue_path(issue)

    fill_in :issue_comment_body, :with => "reassigning to moderators"
    check :reassign
    click_on "Submit"

    issue.reload
    assert_equal "moderator", issue.assigned_role
  end

  def test_issue_index_with_multiple_roles
    user1 = create(:user)
    user2 = create(:user)
    issue1 = create(:issue, :reportable => user1, :assigned_role => "administrator")
    issue2 = create(:issue, :reportable => user2, :assigned_role => "moderator")

    user = create(:administrator_user)
    create(:user_role, :user => user, :role => "moderator")
    sign_in_as(user)

    visit issues_path

    assert page.has_link?(I18n.t("issues.index.reports_count", :count => issue1.reports_count), :href => issue_path(issue1))
    assert page.has_link?(I18n.t("issues.index.reports_count", :count => issue2.reports_count), :href => issue_path(issue2))
  end
end
