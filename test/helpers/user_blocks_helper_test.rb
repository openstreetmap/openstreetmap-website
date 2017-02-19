require "test_helper"

class UserBlocksHelperTest < ActionView::TestCase
  include ApplicationHelper

  def test_block_status
    block = create(:user_block, :needs_view, :ends_at => Time.now.getutc)
    assert_equal I18n.t("user_block.helper.until_login"), block_status(block)

    block_end = Time.now.getutc + 60.minutes
    block = create(:user_block, :needs_view, :ends_at => block_end)
    assert_equal I18n.t("user_block.helper.time_future_and_until_login", :time => friendly_date(block_end)), block_status(block)

    block_end = Time.now.getutc + 60.minutes
    block = create(:user_block, :ends_at => block_end)
    assert_equal I18n.t("user_block.helper.time_future", :time => friendly_date(block_end)), block_status(block)
  end
end
