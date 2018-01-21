require "test_helper"

class UserBlocksHelperTest < ActionView::TestCase
  include ApplicationHelper

  def test_block_status
    block = create(:user_block, :needs_view, :ends_at => Time.now.getutc)
    assert_equal "Active until the user logs in.", block_status(block)

    block = create(:user_block, :needs_view, :ends_at => Time.now.getutc + 1.hour)
    assert_match %r{^Ends in <span title=".*">about 1 hour</span> and after the user has logged in\.$}, block_status(block)

    block = create(:user_block, :ends_at => Time.now.getutc + 1.hour)
    assert_match %r{^Ends in <span title=".*">about 1 hour</span>\.$}, block_status(block)
  end
end
