# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  deliver_by :email do |config|
    config.queue = "mailers"
    config.mailer = "UserMailer"
    config.method = -> { mailer_method }
  end
end
