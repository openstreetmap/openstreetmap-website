# frozen_string_literal: true

class ChangesetCommentNotifier < ApplicationNotifier
  recipients lambda {
    changeset = record.changeset
    changeset.subscribers.visible.where.not(:id => record.author_id)
  }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "changeset_comment_notification"

    # Example of notification settings in action
    # config.if = -> { recipient.receives_notifications?(:for => :changeset_comment, :via => email) }
  end
end
