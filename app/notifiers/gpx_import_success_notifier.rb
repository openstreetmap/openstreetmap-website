# frozen_string_literal: true

class GpxImportSuccessNotifier < ApplicationNotifier
  recipients -> { record.user }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "gpx_success"
    config.if = -> { recipient.notification_preferences.gpx_import_success.include?("email") }
  end
end
