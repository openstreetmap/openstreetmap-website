class Oauth2AuthorizationsController < Doorkeeper::AuthorizationsController
  layout "site"

  prepend_before_action :authorize_web
  before_action :set_locale
  before_action :allow_all_form_action, :only => [:new]

  authorize_resource :class => false

  private

  def allow_all_form_action
    override_content_security_policy_directives(:form_action => []) if Settings.csp_enforce || Settings.key?(:csp_report_url)
  end
end
