# frozen_string_literal: true

module UserNotificationPreferencesHelper
  def user_notification_events
    UserNotificationPreferences::EVENTS
  end

  def user_notification_mechanisms
    UserNotificationPreferences::MECHANISMS
  end
end
