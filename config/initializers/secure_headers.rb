if defined?(CSP_REPORT_URL)
  csp_policy = {
    :default_src => %w['self'],
    :child_src => %w['self'],
    :connect_src => %w['self'],
    :font_src => %w['none'],
    :form_action => %w['self'],
    :frame_ancestors => %w['self'],
    :frame_src => %w['self'],
    :img_src => %w['self' data: www.gravatar.com *.wp.com *.tile.openstreetmap.org *.tile.thunderforest.com *.openstreetmap.fr],
    :media_src => %w['none'],
    :object_src => %w['self'],
    :plugin_types => %w[],
    :script_src => %w['self'],
    :style_src => %w['self'],
    :report_uri => [CSP_REPORT_URL]
  }

  csp_policy[:connect_src] << PIWIK["location"] if defined?(PIWIK)
  csp_policy[:img_src] << PIWIK["location"] if defined?(PIWIK)
  csp_policy[:script_src] << PIWIK["location"] if defined?(PIWIK)
else
  csp_policy = SecureHeaders::OPT_OUT
end

cookie_policy = {
  :secure => SecureHeaders::OPT_OUT,
  :httponly => SecureHeaders::OPT_OUT
}

SecureHeaders::Configuration.default do |config|
  config.hsts = SecureHeaders::OPT_OUT
  config.csp = SecureHeaders::OPT_OUT
  config.csp_report_only = csp_policy
  config.cookies = cookie_policy
end
