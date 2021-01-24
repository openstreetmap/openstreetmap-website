class TraceImporterJob < ApplicationJob
  queue_as :traces

  def perform(trace)
    gpx = trace.import

    if gpx.actual_points.positive?
      UserMailer.gpx_success(trace, gpx.actual_points).deliver
    else
      UserMailer.gpx_failure(trace, "0 points parsed ok. Do they all have lat,lng,alt,timestamp?").deliver
      trace.destroy
    end
  rescue StandardError => e
    logger.info e.to_s
    e.backtrace.each { |l| logger.info l }
    UserMailer.gpx_failure(trace, "#{e}\n#{e.backtrace.join("\n")}").deliver
    trace.destroy
  end
end
