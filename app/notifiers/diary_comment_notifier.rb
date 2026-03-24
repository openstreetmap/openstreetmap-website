# frozen_string_literal: true

class DiaryCommentNotifier < ApplicationNotifier
  recipients -> { record.notifiable_subscribers }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "diary_comment_notification"
  end
end
