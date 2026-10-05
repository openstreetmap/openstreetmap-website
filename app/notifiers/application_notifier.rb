# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  notification_methods do
    def record_required?
      true
    end
  end

  def self.web_notification_types
    %w[
      ChangesetCommentNotifier::Notification
      DiaryCommentNotifier::Notification
      GpxImportFailureNotifier::Notification
      GpxImportSuccessNotifier::Notification
      NewFollowerNotifier::Notification
      NoteCommentNotifier::Notification
    ].freeze
  end
end
