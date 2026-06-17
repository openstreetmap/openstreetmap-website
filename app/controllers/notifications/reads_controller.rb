# frozen_string_literal: true

module Notifications
  class ReadsController < ApplicationController
    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_writable

    authorize_resource :class => :notification_read

    def create
      update_notifications(:read_at => Time.zone.now)
    end

    def destroy
      update_notifications(:read_at => nil)
    end

    private

    def update_notifications(update)
      notifications = current_user.web_notifications.where(:id => params[:notification_ids])
      notifications.update(update)
      redirect_back_or_to notifications_path
    end
  end
end
