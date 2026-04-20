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

    def to_partial_path
      event_type_name = self.class.event_type_name_of(@notification)
      "notifications/#{event_type_name.underscore}"
    end

    def timestamp
      record.created_at
    end
  end

  class ChangesetCommentNotification < Notification
    delegate :changeset, :to => :record
    delegate :id, :to => :changeset, :prefix => true

    def changeset_summary
      changeset.comment
    end

    def commenter
      record.author
    end

    def comment_id
      record.id
    end

    def comment_body
      record.body
    end
  end

  class NoteCommentNotification < Notification
    delegate :note, :to => :record
    delegate :id, :to => :note, :prefix => true

    def comment_body
      record.body
    end

    def comment_id
      record.id
    end

    def commenter
      record.author
    end

    def note_text
      note.description
    end
  end

  include Enumerable

  LISTABLE_NOTIFICATIONS = %w[
    ChangesetCommentNotifier::Notification
    NoteCommentNotifier::Notification
  ].freeze

  def initialize(user)
    @user = user
  end

  def each(&)
    @user
      .notifications
      .where(:type => LISTABLE_NOTIFICATIONS)
      .newest_first
      .map { |instance| Notification.from(instance) }
      .each(&)
  end

  def empty?
    none?
  end
end
