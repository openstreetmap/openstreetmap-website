# frozen_string_literal: true

require "application_system_test_case"

class WebNotificationsTest < ApplicationSystemTestCase
  test "no notifications available" do
    user = create(:user)
    sign_in_as(user)

    click_on user.display_name
    click_on "My Notifications"

    assert_text "Notifications"
    assert_text "You have no notifications"
  end

  test "read latest notifications" do
    changeset_author = create(:user)
    commenter = create(:user, :display_name => "Commenter")
    setup_changeset_comment(
      :changeset_author => changeset_author,
      :commenter => commenter
    )

    sign_in_as(changeset_author)

    click_on changeset_author.display_name
    click_on "My Notifications"

    assert_text "Notifications"
    assert_text "Changeset comment"
    assert_text "User Commenter left a comment on changeset"
  end

  test "pagination" do
    changeset_author = create(:user)
    commenter = create(:user, :display_name => "Commenter")
    1.upto(30).each do |i|
      setup_changeset_comment(
        :changeset_author => changeset_author,
        :commenter => commenter,
        :comment_attrs => {
          :body => "This is comment number #{i}"
        }
      )
    end

    sign_in_as(changeset_author)

    click_on changeset_author.display_name
    click_on "My Notifications"

    assert_text "This is comment number 30"
    assert_no_text "This is comment number 10"
    click_on "Older Notifications"
    assert_no_text "This is comment number 30"
    assert_text "This is comment number 10"
  end

  private

  def setup_changeset_comment(changeset_author:, commenter:, comment_attrs: {})
    changeset = create(:changeset, :user => changeset_author)
    create(:changeset_subscription, :changeset => changeset, :subscriber => changeset_author)

    comment = create(:changeset_comment, :changeset => changeset, :author => commenter, **comment_attrs)
    create(:changeset_subscription, :changeset => changeset, :subscriber => commenter)
    ChangesetCommentNotifier.with(:record => comment).deliver
  end
end
