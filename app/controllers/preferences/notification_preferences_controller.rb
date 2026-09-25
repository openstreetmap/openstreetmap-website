# frozen_string_literal: true

module Preferences
  class NotificationPreferencesController < PreferencesController
    private

    def update_preferences
      current_user.notification_preferences.update(params[:user_notification_preferences])
    end
  end
end
