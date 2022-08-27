Rails.application.config.assets.configure do |env|
  env.register_exporter %w[text/* application/javascript application/json application/xml image/x-icon image/svg+xml], Sprockets::ExportersPack::BrotliExporter
end
