# frozen_string_literal: true

Rails.application.config.to_prepare do
  Noticed::EventJob.queue_as :notifiers
  Noticed::DeliveryMethods::Email.queue_as :mailers
end
