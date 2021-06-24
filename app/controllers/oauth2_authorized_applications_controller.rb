class Oauth2AuthorizedApplicationsController < Doorkeeper::AuthorizedApplicationsController
  layout "site"

  prepend_before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false
end
