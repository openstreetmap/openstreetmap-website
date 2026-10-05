# frozen_string_literal: true

class NotificationsController < ApplicationController
  include PaginationMethods

  layout :site_layout

  before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  before_action :check_database_readable
  before_action :check_database_writable, :only => [:destroy]

  def index
    notifications = current_user.web_notifications
    @notifications = get_page_items(notifications)
    @params = params.permit
  end

  def destroy
    ids_to_delete =
      params
      .expect(:notifications => {})
      .to_unsafe_h
      .select { |_k, v| v == "delete" }
      .keys
      .map { |id| Integer(id) }

    current_user.web_notifications.where(:id => ids_to_delete).delete_all

    redirect_back_or_to notifications_path
  end
end
