class TraceDestroyerJob < ApplicationJob
  queue_as :default

  def perform(trace)
    trace.destroy
  end
end
