class TraceDestroyerJob < ApplicationJob
  queue_as :traces

  def perform(trace)
    trace.destroy
  end
end
