require "test_helper"

class UserBlocksHelperTest < ActionView::TestCase
  include ApplicationHelper

  def test_block_status
    block = create(:user_block, :needs_view, :ends_at => Time.now.utc)
    assert_equal "Active until the user logs in.", block_status(block)

    block = create(:user_block, :needs_view, :ends_at => Time.now.utc + 1.hour)
    assert_match %r{^Ends in <time title=".*" datetime=".*">about 1 hour</time> and after the user has logged in\.$}, block_status(block)

    block = create(:user_block, :ends_at => Time.now.utc + 1.hour)
    assert_match %r{^Ends in <time title=".* datetime=".*">about 1 hour</time>\.$}, block_status(block)
  end

  def test_block_short_status
    freeze_time do
      future_end_block = create(:user_block, :ends_at => Time.now.utc + 48.hours)
      unread_future_end_block = create(:user_block, :needs_view, :ends_at => Time.now.utc + 48.hours)
      past_end_block = create(:user_block, :ends_at => Time.now.utc + 1.hour)
      unread_past_end_block = create(:user_block, :needs_view, :ends_at => Time.now.utc + 1.hour)

      travel 24.hours

      assert_equal "active", block_short_status(future_end_block)
      assert_equal "active", block_short_status(unread_future_end_block)
      assert_equal "ended", block_short_status(past_end_block)
      assert_equal "active until read", block_short_status(unread_past_end_block)
    end
  end

  def test_block_short_status_with_immediate_update
    freeze_time do
      block = UserBlock.new :user => create(:user),
                            :creator => create(:moderator_user),
                            :reason => "because",
                            :created_at => Time.now.utc,
                            :ends_at => Time.now.utc,
                            :deactivates_at => Time.now.utc,
                            :needs_view => false

      travel 1.second

      block.save

      assert_equal "ended", block_short_status(block)
    end
  end

  def test_block_short_status_read
    freeze_time do
      block = create(:user_block, :needs_view, :ends_at => Time.now.utc)

      travel 24.hours

      assert_equal "active until read", block_short_status(block)

      block.update(:needs_view => false, :deactivates_at => Time.now.utc)

      read_date = Time.now.utc.to_date.strftime
      short_status_dom = Rails::Dom::Testing.html_document.parse(block_short_status(block))
      assert_dom short_status_dom, ":root", :text => "read at #{read_date}"

      travel 24.hours

      block.update(:reason => "updated reason")

      short_status_dom = Rails::Dom::Testing.html_document.parse(block_short_status(block))
      assert_dom short_status_dom, ":root", :text => "read at #{read_date}"
    end
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
