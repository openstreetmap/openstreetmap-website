# frozen_string_literal: true

require "test_helper"

class DiaryCommentTest < ActiveSupport::TestCase
  test "body must be present" do
    comment = build(:diary_comment, :body => "")
    assert_not comment.valid?
    assert_not_nil comment.errors[:body], "no validation error for missing body"
  end

  test "body must not be too long" do
    comment = build(:diary_comment, :body => "x" * 65536)
    assert_predicate comment, :valid?

    comment = build(:diary_comment, :body => "x" * 65537)
    assert_not_predicate comment, :valid?
    assert_not_nil comment.errors[:body], "no validation error for body too long"
  end

  test "the correct subscribers are notified" do
    commenter1 = create(:user)
    commenter2 = create(:user, :suspended)
    commenter3 = create(:user)
    commenter4 = create(:user)
    diary_entry = create(:diary_entry)
    create(:diary_entry_subscription, :diary_entry => diary_entry, :user => commenter1)
    create(:diary_entry_subscription, :diary_entry => diary_entry, :user => commenter2)
    create(:diary_entry_subscription, :diary_entry => diary_entry, :user => commenter3)
    create(:diary_entry_subscription, :diary_entry => diary_entry, :user => commenter4)
    comment = create(:diary_comment, :diary_entry => diary_entry, :user => commenter4)

    assert_equal comment.notifiable_subscribers.sort, [commenter1, commenter3].sort
  end
end
