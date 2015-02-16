# -*- coding: utf-8 -*-
require 'test_helper'

class NoteTest < ActiveSupport::TestCase
  fixtures :users, :notes, :note_comments

  def test_status_valid
    ok = %w(open closed hidden)
    bad = %w(expropriated fubared)

    ok.each do |status|
      note = notes(:open_note)
      note.status = status
      assert note.valid?, "#{status} is invalid, when it should be"
    end

    bad.each do |status|
      note = notes(:open_note)
      note.status = status
      assert !note.valid?, "#{status} is valid when it shouldn't be"
    end
  end

  def test_close
    note = notes(:open_note)
    assert_equal "open", note.status
    assert_nil note.closed_at
    note.close
    assert_equal "closed", note.status
    assert_not_nil note.closed_at
  end

  def test_reopen
    note = notes(:closed_note_with_comment)
    assert_equal "closed", note.status
    assert_not_nil note.closed_at
    note.reopen
    assert_equal "open", note.status
    assert_nil note.closed_at
  end

  def test_visible?
    assert_equal true, notes(:open_note).visible?
    assert_equal true, notes(:note_with_hidden_comment).visible?
    assert_equal false, notes(:hidden_note_with_comment).visible?
  end

  def test_closed?
    assert_equal true, notes(:closed_note_with_comment).closed?
    assert_equal false, notes(:open_note).closed?
  end

  def test_author
    assert_nil notes(:open_note).author
    assert_equal users(:normal_user), notes(:note_with_comments_by_users).author
  end

  def test_author_ip
    assert_equal IPAddr.new("192.168.1.1"), notes(:open_note).author_ip
    assert_nil notes(:note_with_comments_by_users).author_ip
  end
end
