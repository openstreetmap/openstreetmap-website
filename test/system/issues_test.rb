require "application_system_test_case"

class IssuesTest < ApplicationSystemTestCase
  def test_view_issues_normal_user
    sign_in_as(create(:user))

    visit issues_path
    assert page.has_content?(I18n.t("application.require_admin.not_an_admin"))
  end

  def test_view_no_issues
    sign_in_as(create(:moderator_user))

    visit issues_path
    assert page.has_content?(I18n.t(".issues.index.search.issues_not_found"))
  end

  def test_view_issues
    sign_in_as(create(:moderator_user))
    issues = create_list(:issue, 3, :assigned_role => "moderator")

    visit issues_path
    assert page.has_content?(issues.first.reported_user.display_name)
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
    assert page.has_content?(I18n.t(".issues.index.search.issues_not_found"))

    # User doesn't exist
    visit issues_path
    fill_in "search_by_user", :with => "Nonexistant User"
    click_on "Search"
    assert page.has_content?(I18n.t(".issues.index.search.user_not_found"))

    # Find Issue against bad_user
    visit issues_path
    fill_in "search_by_user", :with => bad_user.display_name
    click_on "Search"
    assert !page.has_content?(I18n.t(".issues.index.search.issues_not_found"))
  end

  def test_commenting
    issue = create(:issue)
    sign_in_as(create(:moderator_user))

    visit issue_path(issue)

    fill_in :issue_comment_body, :with => "test comment"
    click_on "Submit"
    assert page.has_content?(I18n.t(".issues.comment.comment_created"))
    assert page.has_content?("test comment")

    issue.reload
    assert_equal issue.comments.first.body, "test comment"
  end
end
