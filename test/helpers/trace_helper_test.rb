# frozen_string_literal: true

require "test_helper"

class TraceHelperTest < ActionView::TestCase
  test "trace_visibility_options includes a legacy option for traces that have it" do
    public_trace = build(:trace, :visibility => "public")
    options = trace_visibility_options(public_trace)
    assert_equal %w[public trackable identifiable], options.map(&:last)

    private_trace = build(:trace, :visibility => "private")
    options = trace_visibility_options(private_trace)
    assert_equal %w[private trackable identifiable], options.map(&:last)
  end

  test "trace_visibility_options only includes current visibilities for traces without a legacy one" do
    trackable_trace = build(:trace, :visibility => "trackable")
    options = trace_visibility_options(trackable_trace)
    assert_equal %w[trackable identifiable], options.map(&:last)

    identifiable_trace = build(:trace, :visibility => "identifiable")
    options = trace_visibility_options(identifiable_trace)
    assert_equal %w[trackable identifiable], options.map(&:last)
  end
end
