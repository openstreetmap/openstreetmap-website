class DashboardsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  before_action :check_database_readable

  def show
    @followings = current_user.followings
    @nearby_users = current_user.nearby - @followings
  end
end
