# frozen_string_literal: true

class GpxImportSuccessNotifier < ApplicationNotifier
  recipients -> { record.user }

  validates :record, :presence => true

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = "gpx_success"
  end
end
