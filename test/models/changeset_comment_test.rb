# frozen_string_literal: true

require "test_helper"

class ChangesetCommentTest < ActiveSupport::TestCase
  # validations
  def test_does_not_accept_invalid_author
    comment = create(:changeset_comment)

    comment.author = nil
    assert_not_predicate comment, :valid?

    comment.author_id = 999111
    assert_not_predicate comment, :valid?
  end

  def test_does_not_accept_invalid_changeset
    comment = create(:changeset_comment)

    comment.changeset = nil
    assert_not_predicate comment, :valid?

    comment.changeset_id = 999111
    assert_not_predicate comment, :valid?
  end

  def test_does_not_accept_empty_visible
    comment = create(:changeset_comment)

    comment.visible = nil
    assert_not_predicate comment, :valid?
  end

  def test_comments_of_changeset_count
    changeset = create(:changeset)
    create_list(:changeset_comment, 3, :changeset_id => changeset.id)
    assert_equal 3, Changeset.find(changeset.id).comments.count
  end

  def test_body_valid
    ok = %W[Name vergrößern foo\nbar
            ルシステムにも対応します 輕觸搖晃的遊戲]
    bad = ["foo\x00bar", "foo\x08bar", "foo\x1fbar", "foo\x7fbar",
           "foo\ufffebar", "foo\uffffbar"]

    ok.each do |body|
      changeset_comment = create(:changeset_comment)
      changeset_comment.body = body
      assert_predicate changeset_comment, :valid?, "#{body} is invalid, when it should be"
    end

    bad.each do |body|
      changeset_comment = create(:changeset_comment)
      changeset_comment.body = body
      assert_not_predicate changeset_comment, :valid?, "#{body} is valid when it shouldn't be"
    end
  end

  def test_notifiable_subscribers
    commenter1 = create(:user)
    commenter2 = create(:user, :suspended)
    commenter3 = create(:user)
    commenter4 = create(:user)
    changeset = create(:changeset)
    create(:changeset_subscription, :changeset => changeset, :subscriber => commenter1)
    create(:changeset_subscription, :changeset => changeset, :subscriber => commenter2)
    create(:changeset_subscription, :changeset => changeset, :subscriber => commenter3)
    create(:changeset_subscription, :changeset => changeset, :subscriber => commenter4)
    comment = create(:changeset_comment, :changeset => changeset, :author => commenter4)

    assert_equal comment.notifiable_subscribers.sort, [commenter1, commenter3].sort
  end

  def test_mentioned_users
    sangyoon = create(:user, :display_name => "Sangyoon")
    dion = create(:user, :display_name => "Dion")
    create(:user, :display_name => "Bystander")
    comment = create(:changeset_comment, :body => "@Sangyoon and @Dion, please check")

    assert_equal [sangyoon, dion].sort, comment.mentioned_users.sort
  end

  def test_mentioned_users_unknown_name
    comment = create(:changeset_comment, :body => "@NoSuchUser please check")

    assert_empty comment.mentioned_users
  end

  def test_mentioned_users_is_case_sensitive
    create(:user, :display_name => "Sangyoon")
    comment = create(:changeset_comment, :body => "@sangyoon please check")

    assert_empty comment.mentioned_users
  end

  def test_mentioned_users_excludes_inactive_users
    create(:user, :suspended, :display_name => "Suspended")
    create(:user, :deleted, :display_name => "Deleted")
    comment = create(:changeset_comment, :body => "@Suspended @Deleted please check")

    assert_empty comment.mentioned_users
  end
end
