# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  self.delivery_job = ActionMailer::MailDeliveryJob
end
