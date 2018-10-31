class TraceDestroyerJob < ApplicationJob
  queue_as :default

  def perform(trace)
    trace.destroy
  rescue StandardError => ex
    logger.info ex.to_s
    ex.backtrace.each { |l| logger.info l }
  end
end
