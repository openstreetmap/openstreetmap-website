if defined?(CSP_REPORT_URL)
  policy = {
    :default_src => %w('self'),
    :child_src => %w('self'),
    :connect_src => %w('self'),
    :font_src => %w('none'),
    :form_action => %w('self'),
    :frame_ancestors => %w('self'),
    :img_src => %w('self' data: www.gravatar.com *.wp.com *.tile.openstreetmap.org *.tile.thunderforest.com *.openstreetmap.fr),
    :media_src => %w('none'),
    :object_src => %w('self'),
    :plugin_types => %w('none'),
    :script_src => %w('self'),
    :style_src => %w('self' 'unsafe-inline'),
    :report_uri => [CSP_REPORT_URL]
  }

  policy[:script_src] << PIWIK["location"] if defined?(PIWIK)
else
  policy = SecureHeaders::OPT_OUT
end

SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=0"
  config.csp = SecureHeaders::OPT_OUT
  config.csp_report_only = policy
end
