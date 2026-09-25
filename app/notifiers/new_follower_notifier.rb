# frozen_string_literal: true

class NewFollowerNotifier < ApplicationNotifier
  recipients -> { record.following }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "follow_notification"
    config.if = -> { recipient.notification_preferences.new_follower.include?("email") }
  end
end
