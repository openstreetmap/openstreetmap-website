# frozen_string_literal: true

class TraceImporterJob < ApplicationJob
  queue_as :traces

  def perform(trace)
    gpx = trace.import

    if gpx.actual_points.positive?
      GpxImportSuccessNotifier.with(:record => trace, :possible_points => gpx.actual_points).deliver_later
    else
      handle_import_failure_notification(trace, "0 points parsed ok. Do they all have lat,lng,alt,timestamp?")
    end
  rescue LibXML::XML::Error => e
    logger.info e.to_s
    handle_import_failure_notification(trace, e.to_s)
  rescue StandardError => e
    logger.info e.to_s
    e.backtrace.each { |l| logger.info l }
    handle_import_failure_notification(trace, "#{e}\n#{e.backtrace.join("\n")}")
  end

  private

  def handle_import_failure_notification(trace, error)
    GpxImportFailureNotifier.with(
      :trace_name => trace.name,
      :trace_description => trace.description,
      :trace_tags => trace.tags.map(&:tag),
      :error => error
    ).deliver_later(trace.user)
    trace.destroy
  end
end
