# frozen_string_literal: true

class NoteCommentNotifier < ApplicationNotifier
  recipients -> { record.notifiable_subscribers }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "note_comment_notification"
    config.if = -> { recipient.notification_preferences.note_comment.include?("email") }
  end
end
