class QueriesController < ApplicationController
  layout :map_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth
  before_action :update_totp
  authorize_resource :class => false

  def show; end
end
