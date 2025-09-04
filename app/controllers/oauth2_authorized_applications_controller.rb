# frozen_string_literal: true

class Oauth2AuthorizedApplicationsController < Doorkeeper::AuthorizedApplicationsController
  layout :site_layout

  prepend_before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false
end
