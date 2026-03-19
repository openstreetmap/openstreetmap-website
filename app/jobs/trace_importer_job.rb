# frozen_string_literal: true

class TraceImporterJob < ApplicationJob
  queue_as :traces

  def perform(trace)
    gpx = trace.import

    if gpx.actual_points.positive?
      GpxImportSuccessNotifier.with(:record => trace, :possible_points => gpx.actual_points).deliver_later
    else
      UserMailer.with(:trace => trace, :error => "0 points parsed ok. Do they all have lat,lng,alt,timestamp?").gpx_failure.deliver
      trace.destroy
    end
  rescue LibXML::XML::Error => e
    logger.info e.to_s
    UserMailer.with(:trace => trace, :error => e).gpx_failure.deliver
    trace.destroy
  rescue StandardError => e
    logger.info e.to_s
    e.backtrace.each { |l| logger.info l }
    UserMailer.with(:trace => trace, :error => "#{e}\n#{e.backtrace.join("\n")}").gpx_failure.deliver
    trace.destroy
  end
end
