# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  connect_src = [:self]
  img_src = [:self, :data, "www.gravatar.com", "*.wp.com", "tile.openstreetmap.org", "gps.tile.openstreetmap.org", "*.tile.thunderforest.com", "tile.tracestrack.com", "*.openstreetmap.fr"]
  script_src = [:self]

  connect_src << Settings.matomo["location"] if defined?(Settings.matomo)
  img_src << Settings.matomo["location"] if defined?(Settings.matomo)
  script_src << Settings.matomo["location"] if defined?(Settings.matomo)

  img_src << Settings.avatar_storage_url if Settings.key?(:avatar_storage_url)
  img_src << Settings.trace_image_storage_url if Settings.key?(:trace_image_storage_url)

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.child_src(:self)
    policy.connect_src(*connect_src)
    policy.font_src(:none)
    policy.form_action(:self)
    policy.frame_ancestors(:self)
    policy.frame_src(:self)
    policy.img_src(*img_src)
    policy.manifest_src(:self)
    policy.media_src(:none)
    policy.object_src(:self)
    policy.plugin_types
    policy.script_src(*script_src)
    policy.style_src(:self)
    policy.worker_src(:none)
    policy.manifest_src(:self)
    policy.report_uri(Settings.csp_report_url) if Settings.key?(:csp_report_url)
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(24) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy.
  config.content_security_policy_report_only = true unless Settings.csp_enforce
end
