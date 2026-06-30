# frozen_string_literal: true

class NotificationsController < ApplicationController
  include PaginationMethods

  layout :site_layout

  before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  before_action :check_database_readable

  def index
    records = UserNotifications.new(current_user).notification_records
    @notifications = get_page_items(records)
    @params = params.permit
  end
end
