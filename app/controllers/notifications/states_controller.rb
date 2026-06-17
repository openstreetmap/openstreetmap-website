# frozen_string_literal: true

module Notifications
  class StatesController < ApplicationController
    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_writable

    def create
      notifications = current_user.notifications.where(:id => params[:notification_ids])
      update_state(notifications)
      redirect_back_or_to notifications_path
    end

    private

    def update_state(notifications)
      raise NotImplementedError
    end
  end
end
