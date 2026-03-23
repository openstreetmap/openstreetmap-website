# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  deliver_by :email do |config|
    config.queue = "mailers"
    config.mailer = "UserMailer"
    config.method = -> { mailer_method }
  end

  notification_methods do
    def mailer_method
      raise NotImplementedError, "Remember to implement `mailer_method` under `notification_methods` in `#{event.class.name}`"
    end
  end
end
