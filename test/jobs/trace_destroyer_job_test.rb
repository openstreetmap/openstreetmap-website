# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class TraceDestroyerJobTest < ActiveJob::TestCase
  def test_destroy_called
    trace = create(:trace)
    destroyed = false

    # Check that the trace is locked, so that any import of it finishes
    # first, and that trace.destroy is called
    trace.stub(:destroy, -> { destroyed = true }) do
      assert_queries_match(/for update/i, :count => 1) do
        TraceDestroyerJob.perform_now(trace)
      end
    end

    assert destroyed
  end
end
