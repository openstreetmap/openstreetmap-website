# frozen_string_literal: true

module NotificationsHelper
  def partial_path_for_notification(notification)
    event_type_name = notification_event_type_name(notification)

    "notifications/#{event_type_name}"
  end

  def notification_event_type_name(notification)
    # Turn "ChangesetCommentNotifier::Notification" into "ChangesetComment"
    notification
      .class
      .name
      .sub("Notifier::Notification", "")
      .underscore
  end
end
