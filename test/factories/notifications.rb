# frozen_string_literal: true

FactoryBot.define do
  factory :notification, :class => "ApplicationNotifier::Notification" do
    initialize_with do
      notifier_class = self.notifier_class || "#{record.class.name}Notifier".constantize
      notification_class = notifier_class::Notification
      notification_class.new
    end

    recipient :factory => :user

    event do
      association :notifier, :record => record, :notifier_class => notifier_class, :params => notifier_params
    end

    transient do
      record { nil }
      notifier_class { nil }
      notifier_params { nil }
    end
  end

  factory :notifier, :class => "ApplicationNotifier" do
    initialize_with do
      notifier_class = self.notifier_class || "#{record.class.name}Notifier".constantize
      notifier_class.new(:record => record)
    end

    transient do
      notifier_class { nil }
    end
  end

  factory :changeset_comment_notification, :class => "ChangesetCommentNotifier::Notification" do
    event :factory => :changeset_comment_notifier
    recipient :factory => :user
  end

  factory :changeset_comment_notifier, :class => "ChangesetCommentNotifier" do
    record :factory => :changeset_comment
  end

  factory :gpx_import_failure_notification, :class => "GpxImportFailureNotifier::Notification" do
    event :factory => :gpx_import_failure_notifier
    recipient :factory => :user
  end

  factory :gpx_import_failure_notifier, :class => "GpxImportFailureNotifier"
end
