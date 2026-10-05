# frozen_string_literal: true

require "test_helper"

class GpxEventTest < ActiveSupport::TestCase
  def test_validations
    gpx_event_valid({})
    gpx_event_valid({ :action => "removed" })
    gpx_event_valid({ :action => "updated" }, :valid => false)
    gpx_event_valid({ :action => nil }, :valid => false)
    gpx_event_valid({ :gpx_id => nil }, :valid => false)
  end

  def test_event_stays_after_the_trace_is_destroyed
    trace = create(:trace)
    event = create(:gpx_event, :gpx_id => trace.id)

    trace.destroy

    assert GpxEvent.exists?(event.id)
  end

  private

  def gpx_event_valid(attrs, valid: true)
    event = build(:gpx_event)
    event.assign_attributes(attrs)
    assert_equal valid, event.valid?, "Expected #{attrs.inspect} to be #{valid}"
  end
end
