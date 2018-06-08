# frozen_string_literal: true

csp_policy = {
  :preserve_schemes => true,
  :default_src => %w[self],
  :child_src => %w[self],
  :connect_src => %w[self],
  :font_src => %w[none],
  :form_action => %w[self],
  :frame_ancestors => %w[self],
  :frame_src => %w[self],
  :img_src => %w[self data: www.gravatar.com *.wp.com *.tile.openstreetmap.org *.tile.thunderforest.com *.openstreetmap.fr],
  :manifest_src => %w[none],
  :media_src => %w[none],
  :object_src => %w[self],
  :plugin_types => %w[],
  :script_src => %w[self],
  :style_src => %w[self],
  :worker_src => %w[none],
  :report_uri => []
}

csp_policy[:connect_src] << PIWIK["location"] if defined?(PIWIK)
csp_policy[:img_src] << PIWIK["location"] if defined?(PIWIK)
csp_policy[:script_src] << PIWIK["location"] if defined?(PIWIK)
csp_policy[:report_uri] << CSP_REPORT_URL if defined?(CSP_REPORT_URL)

cookie_policy = {
  :secure => SecureHeaders::OPT_OUT,
  :httponly => SecureHeaders::OPT_OUT
}

SecureHeaders::Configuration.default do |config|
  config.hsts = SecureHeaders::OPT_OUT

  if defined?(CSP_ENFORCE) && CSP_ENFORCE
    config.csp = csp_policy
    config.csp_report_only = SecureHeaders::OPT_OUT
  elsif defined?(CSP_REPORT_URL)
    config.csp = SecureHeaders::OPT_OUT
    config.csp_report_only = csp_policy
  else
    config.csp = SecureHeaders::OPT_OUT
    config.csp_report_only = SecureHeaders::OPT_OUT
  end

  config.cookies = cookie_policy
end
