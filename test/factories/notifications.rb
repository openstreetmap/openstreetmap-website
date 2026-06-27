# frozen_string_literal: true

FactoryBot.define do
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
