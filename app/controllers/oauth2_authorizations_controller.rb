class Oauth2AuthorizationsController < Doorkeeper::AuthorizationsController
  layout "site"

  prepend_before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  def new
    override_content_security_policy_directives(:form_action => []) if Settings.csp_enforce || Settings.key?(:csp_report_url)

    super
  end
end
