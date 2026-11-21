# frozen_string_literal: true

module Notifications
  class ReadsController < StatesController
    authorize_resource :class => :notification_read

    private

    def update_state(notifications)
      notifications.update(:read_at => Time.zone.now)
    end
  end
end
