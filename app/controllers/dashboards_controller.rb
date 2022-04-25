class DashboardsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  before_action :check_database_readable

  def show
    @user = current_user
  end
end
