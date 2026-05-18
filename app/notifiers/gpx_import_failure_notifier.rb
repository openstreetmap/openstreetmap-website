# frozen_string_literal: true

class GpxImportFailureNotifier < ApplicationNotifier
  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "gpx_failure"
    config.if = -> { recipient.notification_preferences.gpx_import_failure.include?("email") }
  end
end
