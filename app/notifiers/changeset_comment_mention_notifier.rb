# frozen_string_literal: true

class ChangesetCommentMentionNotifier < ApplicationNotifier
  recipients -> { record.notifiable_mentioned_users }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "changeset_comment_mention_notification"
    config.if = -> { recipient.notification_preferences.changeset_comment_mention.include?("email") }
  end
end
