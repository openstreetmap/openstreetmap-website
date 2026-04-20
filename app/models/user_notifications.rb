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

  include Enumerable

  LISTABLE_NOTIFICATIONS = [].freeze

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
