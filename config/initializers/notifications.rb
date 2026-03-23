# frozen_string_literal: true

Rails.configuration.after_initialize do
  Noticed::EventJob.queue_as :notifications
end
