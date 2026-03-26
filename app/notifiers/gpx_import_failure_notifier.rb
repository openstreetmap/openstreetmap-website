# frozen_string_literal: true

class GpxImportFailureNotifier < ApplicationNotifier
  recipients -> { record }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "gpx_failure"
  end
end
