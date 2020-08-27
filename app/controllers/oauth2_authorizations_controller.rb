class Oauth2AuthorizationsController < Doorkeeper::AuthorizationsController
  layout "site"

  prepend_before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false
end
