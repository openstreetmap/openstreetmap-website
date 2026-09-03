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

    assert_selector ".web-notification", :count => 20
    assert_text "This is comment number 30"
    assert_no_text "This is comment number 10"
    click_on "Older Notifications"
    assert_selector ".web-notification", :count => 10
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

  test "follower notification is cleaned up after unfollow" do
    follower = create(:user, :display_name => "Follower")
    followed = create(:user)

    follow = create(:follow, :follower => follower, :following => followed)
    NewFollowerNotifier.with(:record => follow).deliver

    sign_in_as(follower)
    visit user_path(followed)
    click_on "Unfollow"
    assert_text "You successfully unfollowed"

    sign_in_as(followed)

    click_on followed.display_name
    click_on "My Notifications"

    assert_text "Notifications"
    assert_text "You have no notifications"
  end

  test "historical orphaned follower notification is skipped" do
    follower = create(:user, :display_name => "Follower")
    followed = create(:user)

    follow = create(:follow, :follower => follower, :following => followed)
    NewFollowerNotifier.with(:record => follow).deliver

    Follow.where(:id => follow.id).delete_all

    sign_in_as(followed)

    click_on followed.display_name
    click_on "My Notifications"

    assert_text "Notifications"
    assert_no_selector ".web-notification"
  end

  test "GPX import success notification is cleaned up after trace is destroyed" do
    user = create(:user)
    trace = create(:trace, :user => user)
    GpxImportSuccessNotifier.with(:record => trace, :possible_points => 100).deliver

    trace.destroy

    sign_in_as(user)
    click_on user.display_name
    click_on "My Notifications"

    assert_text "Notifications"
    assert_text "You have no notifications"
  end

  test "historical orphaned GPX import success notification is skipped" do
    user = create(:user)
    trace = create(:trace, :user => user)
    GpxImportSuccessNotifier.with(:record => trace, :possible_points => 100).deliver

    Trace.where(:id => trace.id).delete_all

    sign_in_as(user)
    click_on user.display_name
    click_on "My Notifications"

    assert_text "Notifications"
    assert_no_selector ".web-notification"
  end

  test "GPX import failure notification without a record is still rendered" do
    user = create(:user)
    GpxImportFailureNotifier.with(
      :trace_name => "bad_trace.gpx",
      :trace_description => "bad",
      :trace_tags => [],
      :error => "0 points parsed ok"
    ).deliver(user)

    sign_in_as(user)
    click_on user.display_name
    click_on "My Notifications"

    assert_text "Notifications"
    assert_selector ".web-notification"
    assert_text "bad_trace.gpx"
  end
end
