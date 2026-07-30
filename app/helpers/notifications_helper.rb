# frozen_string_literal: true

module NotificationsHelper
  def partial_path_for_notification(notification)
    # Turn "ChangesetCommentNotifier::Notification" into "ChangesetComment"
    event_type_name = notification.class.name.sub("Notifier::Notification", "")

    "notifications/#{event_type_name.underscore}"
  end
end
