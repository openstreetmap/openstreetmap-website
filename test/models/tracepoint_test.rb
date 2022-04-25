require "test_helper"

class TracepointTest < ActiveSupport::TestCase
  def test_timestamp_required
    tracepoint = create(:tracepoint)
    assert_predicate tracepoint, :valid?
    tracepoint.timestamp = nil
    assert_not tracepoint.valid?
  end
end
