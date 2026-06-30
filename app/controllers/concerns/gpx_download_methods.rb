# frozen_string_literal: true

module GpxDownloadMethods
  extend ActiveSupport::Concern

  private

  # Send the stored trace file to the client. It can go back two ways.
  # - If the store serves gzip (S3) and the client accepts it, redirect and let the client unzip it.
  # - Otherwise the server unzips it first and sends plain GPX.
  def send_trace_file(trace)
    if gzipped_by_server?(trace)
      # The response depends on Accept-Encoding, so caches must vary on it.
      response.headers["Vary"] = [response.headers["Vary"], "Accept-Encoding"].compact.join(", ")

      if store_serves_gzip?(trace) && request_accepts_gzip?
        redirect_to rails_blob_path(trace.file, :disposition => "attachment")
      else
        send_data(trace.xml_file.read,
                  :filename => trace.file.filename.to_s,
                  :type => "application/gpx+xml",
                  :disposition => "attachment")
      end
    else
      redirect_to rails_blob_path(trace.file, :disposition => "attachment")
    end
  end

  # True when the server stored this GPX gzipped. Only new files, old traces return false.
  def gzipped_by_server?(trace)
    trace.file.custom_metadata["server_gzipped"].present?
  end

  # True when the store serves the file with its Content-Encoding header (S3, not Disk).
  def store_serves_gzip?(trace)
    trace.file.blob.service.try(:serves_content_encoding?)
  end

  # True when the client can read gzip, so we can send it without unzipping first.
  def request_accepts_gzip?
    request.accept_encoding.to_s.split(",").any? { |encoding| encoding.split(";").first.strip == "gzip" }
  end
end
