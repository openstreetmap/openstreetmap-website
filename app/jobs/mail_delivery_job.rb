class MailDeliveryJob < ActionMailer::MailDeliveryJob
  discard_on ActiveJob::DeserializationError
end
