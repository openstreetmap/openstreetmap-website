# frozen_string_literal: true

if Settings.key?(:sentry_dsn)
  Sentry.init do |config|
    config.dsn = Settings.sentry_dsn
    config.traces_sample_rate = Settings.sentry_traces_sample_rate if Settings.key?(:sentry_traces_sample_rate)
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  end
end
