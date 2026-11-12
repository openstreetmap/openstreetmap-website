# frozen_string_literal: true

if Settings.key?(:sentry_dsn)
  Sentry.init do |config|
    config.dsn = Settings.sentry_dsn
    config.traces_sample_rate = Settings.sentry_traces_sample_rate if Settings.key?(:sentry_traces_sample_rate)
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.data_collection.url_query_params.mode = :deny_list
    config.before_send = lambda do |event, hint|
      # The message includes a random tempfile path, so group by file extension instead
      match = hint[:exception]&.message&.match(/\AVipsForeignLoad: ".*(\.\w+)" is not a known file format/)
      event.fingerprint = ["vips-unknown-file-format", match[1]] if match
      event
    end
  end
end
