# frozen_string_literal: true

if ENV.key?("OTEL_TRACES_EXPORTER")
  require "opentelemetry/sdk"
  require "opentelemetry/instrumentation/all"
  require "opentelemetry/exporter/otlp"

  OpenTelemetry::SDK.configure do |c|
    c.use_all(
      "OpenTelemetry::Instrumentation::Rack" => {
        :allowed_request_headers => %w[X-Request-Id]
      }
    )
  end
end
