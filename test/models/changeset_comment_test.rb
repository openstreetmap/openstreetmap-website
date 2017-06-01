# -*- coding: utf-8 -*-
require "test_helper"

class ChangesetCommentTest < ActiveSupport::TestCase
  # validations
  def test_does_not_accept_invalid_author
    comment = create(:changeset_comment)

    comment.author = nil
    assert !comment.valid?

    comment.author_id = 999111
    assert !comment.valid?
  end

  def test_does_not_accept_invalid_changeset
    comment = create(:changeset_comment)

    comment.changeset = nil
    assert !comment.valid?

    comment.changeset_id = 999111
    assert !comment.valid?
  end

  def test_does_not_accept_empty_visible
    comment = create(:changeset_comment)

    comment.visible = nil
    assert !comment.valid?
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
      assert changeset_comment.valid?, "#{body} is invalid, when it should be"
    end

    bad.each do |body|
      changeset_comment = create(:changeset_comment)
      changeset_comment.body = body
      assert !changeset_comment.valid?, "#{body} is valid when it shouldn't be"
    end
  end
end
