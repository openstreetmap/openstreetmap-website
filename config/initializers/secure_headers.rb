csp_policy = {
  :preserve_schemes => true,
  :default_src => %w['self'],
  :child_src => %w['self'],
  :connect_src => %w['self'],
  :font_src => %w['none'],
  :form_action => %w['self'],
  :frame_ancestors => %w['self'],
  :frame_src => %w['self'],
  :img_src => %w['self' data: www.gravatar.com *.wp.com tile.openstreetmap.org *.tile.openstreetmap.org *.tile.thunderforest.com tileserver.memomaps.de *.openstreetmap.fr],
  :manifest_src => %w['self'],
  :media_src => %w['none'],
  :object_src => %w['self'],
  :plugin_types => %w[],
  :script_src => %w['self'],
  :style_src => %w['self'],
  :worker_src => %w['none'],
  :report_uri => []
}

csp_policy[:connect_src] << Settings.matomo["location"] if defined?(Settings.matomo)
csp_policy[:img_src] << Settings.matomo["location"] if defined?(Settings.matomo)
csp_policy[:script_src] << Settings.matomo["location"] if defined?(Settings.matomo)

csp_policy[:img_src] << Settings.avatar_storage_url if Settings.key?(:avatar_storage_url)
csp_policy[:img_src] << Settings.trace_image_storage_url if Settings.key?(:trace_image_storage_url)

csp_policy[:report_uri] << Settings.csp_report_url if Settings.key?(:csp_report_url)

cookie_policy = {
  :httponly => { :only => ["_osm_session"] }
}

SecureHeaders::Configuration.default do |config|
  config.hsts = SecureHeaders::OPT_OUT
  config.referrer_policy = "strict-origin-when-cross-origin"

  if Settings.csp_enforce
    config.csp = csp_policy
    config.csp_report_only = SecureHeaders::OPT_OUT
  elsif Settings.key?(:csp_report_url)
    config.csp = SecureHeaders::OPT_OUT
    config.csp_report_only = csp_policy
  else
    config.csp = SecureHeaders::OPT_OUT
    config.csp_report_only = SecureHeaders::OPT_OUT
  end

  config.cookies = cookie_policy
end
