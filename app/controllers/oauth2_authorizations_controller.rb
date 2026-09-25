# frozen_string_literal: true

class Oauth2AuthorizationsController < Doorkeeper::AuthorizationsController
  layout :site_layout

  prepend_before_action :authorize_web
  before_action :set_locale

  allow_all_form_action :only => :new

  authorize_resource :class => false

  before_action :check_database_writable
end
