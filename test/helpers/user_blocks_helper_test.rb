require "test_helper"

class UserBlocksHelperTest < ActionView::TestCase
  include ApplicationHelper

  def test_block_status
    block = create(:user_block, :needs_view, :ends_at => Time.now.utc)
    assert_equal "Active until the user logs in.", block_status(block)

    block = create(:user_block, :needs_view, :ends_at => Time.now.utc + 1.hour)
    assert_match %r{^Ends in <span title=".*">about 1 hour</span> and after the user has logged in\.$}, block_status(block)

    block = create(:user_block, :ends_at => Time.now.utc + 1.hour)
    assert_match %r{^Ends in <span title=".*">about 1 hour</span>\.$}, block_status(block)
  end

  def test_block_duration_in_words
    words = block_duration_in_words(364.days)
    assert_equal "11 months", words

    words = block_duration_in_words(24.hours)
    assert_equal "1 day", words

    # Ensure that nil hours is not passed to i18n.t
    words = block_duration_in_words(10.minutes)
    assert_equal "0 hours", words

    words = block_duration_in_words(0)
    assert_equal "0 hours", words

    # Ensure that (slightly) negative durations don't mess everything up
    # This can happen on zero hour blocks when ends_at is a millisecond before created_at
    words = block_duration_in_words(-0.001)
    assert_equal "0 hours", words
  end
end
