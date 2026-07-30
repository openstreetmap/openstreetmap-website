# frozen_string_literal: true

class UserNotifications
  class Notification
    def self.from(notification)
      event_type_name = event_type_name_of(notification)
      klass = "UserNotifications::#{event_type_name}Notification".constantize
      klass.new(notification)
    end

    # Takes "ChangesetCommentNotifier::Notification", returns "ChangesetComment"
    def self.event_type_name_of(notification)
      notification.class.name.sub("Notifier::Notification", "")
    end

    def initialize(notification)
      @notification = notification
    end

    delegate :record, :to => :@notification

    def timestamp
      record.created_at
    end
  end

  class ChangesetCommentNotification < Notification
  end

  class DiaryCommentNotification < Notification
  end

  class GpxImportFailureNotification < Notification
    delegate :params, :created_at, :to => :@notification
  end

  class GpxImportSuccessNotification < Notification
    delegate :params, :to => :@notification
  end

  class NewFollowerNotification < Notification
  end

  class NoteCommentNotification < Notification
  end

  LISTABLE_NOTIFICATIONS = %w[
    ChangesetCommentNotifier::Notification
    DiaryCommentNotifier::Notification
    GpxImportFailureNotifier::Notification
    GpxImportSuccessNotifier::Notification
    NewFollowerNotifier::Notification
    NoteCommentNotifier::Notification
  ].freeze
end
