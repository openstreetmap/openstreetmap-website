class TraceImporterJob < ApplicationJob
  queue_as :traces

  def perform(trace)
    gpx = trace.import

    if gpx.actual_points.positive?
      Notifier.gpx_success(trace, gpx.actual_points).deliver_later
    else
      Notifier.gpx_failure(trace, "0 points parsed ok. Do they all have lat,lng,alt,timestamp?").deliver_later
      trace.destroy
    end
  rescue StandardError => ex
    logger.info ex.to_s
    ex.backtrace.each { |l| logger.info l }
    Notifier.gpx_failure(trace, ex.to_s + "\n" + ex.backtrace.join("\n")).deliver_later
    trace.destroy
  end
end
