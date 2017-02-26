policy = if defined?(CSP_REPORT_URL)
           {
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
             :script_src => %w('self' 'unsafe-inline'),
             :style_src => %w('self' 'unsafe-inline'),
             :report_uri => [CSP_REPORT_URL]
           }
         else
           SecureHeaders::OPT_OUT
         end

SecureHeaders::Configuration.default do |config|
  config.csp = SecureHeaders::OPT_OUT
  config.csp_report_only = policy
end
