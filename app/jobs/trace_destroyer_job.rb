# frozen_string_literal: true

class TraceDestroyerJob < ApplicationJob
  queue_as :traces

  def perform(trace)
    # Lock the trace first so that any import of it finishes before its points are deleted
    trace.with_lock { trace.destroy }
  end
end
