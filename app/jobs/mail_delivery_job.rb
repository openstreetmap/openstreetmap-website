# frozen_string_literal: true

class MailDeliveryJob < ActionMailer::MailDeliveryJob
  discard_on ActiveJob::DeserializationError
end
