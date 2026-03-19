# frozen_string_literal: true

class TraceImporterJob < ApplicationJob
  queue_as :traces

  def perform(trace)
    gpx = trace.import

    if gpx.actual_points.positive?
      GpxImportSuccessNotifier.with(:record => trace, :possible_points => gpx.actual_points).deliver_later
    else
      deliver_import_failure_notification(trace, "0 points parsed ok. Do they all have lat,lng,alt,timestamp?")
      trace.destroy
    end
  rescue LibXML::XML::Error => e
    logger.info e.to_s
    deliver_import_failure_notification(trace, e.to_s)
    trace.destroy
  rescue StandardError => e
    logger.info e.to_s
    e.backtrace.each { |l| logger.info l }
    deliver_import_failure_notification(trace, "#{e}\n#{e.backtrace.join("\n")}")
    trace.destroy
  end

  private

  def deliver_import_failure_notification(trace, error)
    GpxImportFailureNotifier.with(
      :record => trace.user,
      :trace_name => trace.name,
      :trace_description => trace.description,
      :trace_tags => trace.tags.map(&:tag),
      :error => error
    ).deliver_later
  end
end
