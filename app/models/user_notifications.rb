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

  class DiaryCommentNotification < Notification
    delegate :body, :to => :record
    delegate :diary_entry, :to => :record
    delegate :title, :to => :diary_entry, :prefix => true

    def commenter
      record.user
    end

    def comment_id
      record.id
    end

    def comment_body
      record.body
    end

    def diary_author
      diary_entry.user
    end
  end

  class GpxImportFailureNotification < Notification
    def timestamp
      @notification.created_at
    end

    def trace_filename
      @notification.params[:trace_name]
    end

    def trace_description
      @notification.params[:trace_description]
    end

    def trace_tags
      @notification.params[:trace_tags]
    end

    def trace_possible_points
      nil
    end

    def trace_points
      nil
    end

    def error
      @notification.params[:error]
    end
  end

  class GpxImportSuccessNotification < Notification
    delegate :timestamp, :to => :record

    def trace_filename
      record.name
    end

    def trace_description
      record.description
    end

    def trace_tags
      record.tags.map(&:tag)
    end

    def trace_possible_points
      @notification.params[:possible_points]
    end

    def trace_points
      record.size
    end

    delegate :user, :to => :record
  end

  class NewFollowerNotification < Notification
    delegate :follower, :to => :record
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
    DiaryCommentNotifier::Notification
    GpxImportFailureNotifier::Notification
    GpxImportSuccessNotifier::Notification
    NewFollowerNotifier::Notification
    NoteCommentNotifier::Notification
  ].freeze

  def self.wrap(notification_records)
    notification_records.map { |record| Notification.from(record) }
  end

  def initialize(user)
    @user = user
  end

  def notification_records(&)
    @user
      .notifications
      .where(:type => LISTABLE_NOTIFICATIONS)
  end

  def each(&)
    notification_records.each(&)
  end

  def empty?
    none?
  end
end
