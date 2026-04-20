# frozen_string_literal: true

class NotificationsController < ApplicationController
  layout :site_layout

  before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  before_action :check_database_readable

  def index
    @notifications = UserNotifications.new(current_user)
  end
end
