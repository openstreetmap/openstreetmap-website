# frozen_string_literal: true

class DirectMessageNotifier < ApplicationNotifier
  recipients -> { record.recipient }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "message_notification"
    config.if = -> { recipient.notification_preferences.direct_message.include?("email") }
  end
end
