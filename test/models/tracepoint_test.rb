require "test_helper"

class TracepointTest < ActiveSupport::TestCase
  def test_timestamp_required
    tracepoint = create(:tracepoint)
    assert tracepoint.valid?
    tracepoint.timestamp = nil
    assert !tracepoint.valid?
  end
end
