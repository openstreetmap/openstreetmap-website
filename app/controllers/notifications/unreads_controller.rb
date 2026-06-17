# frozen_string_literal: true

module Notifications
  class UnreadsController < ReadsController
    authorize_resource :class => :notification_unread

    private

    def update_state(notifications)
      notifications.update(:read_at => nil)
    end
  end
end
