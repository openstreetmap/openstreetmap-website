# frozen_string_literal: true

class ChangesetCommentNotifier < ApplicationNotifier
  recipients -> { record.notifiable_subscribers }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "changeset_comment_notification"
    config.if = -> { recipient.notification_preferences.changeset_comment.include?("email") }
  end
end
