# coding: utf-8
require "test_helper"

class UserBlocksHelperTest < ActionView::TestCase
  include ApplicationHelper
  def setup
    I18n.locale = "en"
  end

  def teardown
    I18n.locale = "en"
  end

  def test_block_status
    block = UserBlock.create(
      :user_id => 1,
      :creator_id => 2,
      :reason => "testing",
      :needs_view => true,
      :ends_at => Time.now.getutc
    )
    assert_equal I18n.t("user_block.helper.until_login"), block_status(block)
    block_end = Time.now.getutc + 60.minutes
    block = UserBlock.create(
      :user_id => 1,
      :creator_id => 2,
      :reason => "testing",
      :needs_view => true,
      :ends_at => Time.now.getutc + 60.minutes
    )
    assert_equal I18n.t("user_block.helper.time_future_and_until_login", :time => friendly_date(block_end)), block_status(block)
    block_end = Time.now.getutc + 60.minutes
    block = UserBlock.create(
      :user_id => 1,
      :creator_id => 2,
      :reason => "testing",
      :needs_view => false,
      :ends_at => Time.now.getutc + 60.minutes
    )
    assert_equal I18n.t("user_block.helper.time_future", :time => friendly_date(block_end)), block_status(block)
  end
end
