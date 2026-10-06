# frozen_string_literal: true

module Notifications
  class ReadsController < ApplicationController
    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => false

    before_action :check_database_writable

    def create
      notification_ids = Array.wrap(params[:notification_ids]).map { |id| Integer(id) }

      current_user
        .web_notifications
        .where(:id => notification_ids)
        .update(:read_at => Time.zone.now)

      redirect_back_or_to notifications_path
    end
  end
end
