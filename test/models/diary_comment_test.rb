# frozen_string_literal: true

require "test_helper"

class DiaryCommentTest < ActiveSupport::TestCase
  def setup
    # Create the default language for diary entries
    create(:language, :code => "en")
  end

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
end
