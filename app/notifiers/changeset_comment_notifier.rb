# frozen_string_literal: true

class ChangesetCommentNotifier < ApplicationNotifier
  recipients -> { record.notifiable_subscribers }

  validates :record, :presence => true

  notification_methods do
    def mailer_method
      "changeset_comment_notification"
    end
  end
end
