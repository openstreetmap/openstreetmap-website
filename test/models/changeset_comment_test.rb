# -*- coding: utf-8 -*-
require "test_helper"

class ChangesetCommentTest < ActiveSupport::TestCase
  fixtures :changesets, :changeset_comments

  def test_changeset_comment_count
    assert_equal 4, ChangesetComment.count
  end

  # validations
  def test_does_not_accept_invalid_author
    comment = changeset_comments(:normal_comment_1)

    comment.author = nil
    assert !comment.valid?

    comment.author_id = 999111
    assert !comment.valid?
  end

  def test_does_not_accept_invalid_changeset
    comment = changeset_comments(:normal_comment_1)

    comment.changeset = nil
    assert !comment.valid?

    comment.changeset_id = 999111
    assert !comment.valid?
  end

  def test_does_not_accept_empty_visible
    comment = changeset_comments(:normal_comment_1)

    comment.visible = nil
    assert !comment.valid?
  end

  def test_comments_of_changeset_count
    assert_equal 3, Changeset.find(changesets(:normal_user_closed_change).id).comments.count
  end

  def test_body_valid
    ok = %W(Name vergrößern foo\nbar
            ルシステムにも対応します 輕觸搖晃的遊戲)
    bad = ["foo\x00bar", "foo\x08bar", "foo\x1fbar", "foo\x7fbar",
           "foo\ufffebar", "foo\uffffbar"]

    ok.each do |body|
      changeset_comment = changeset_comments(:normal_comment_1)
      changeset_comment.body = body
      assert changeset_comment.valid?, "#{body} is invalid, when it should be"
    end

    bad.each do |body|
      changeset_comment = changeset_comments(:normal_comment_1)
      changeset_comment.body = body
      assert !changeset_comment.valid?, "#{body} is valid when it shouldn't be"
    end
  end
end
