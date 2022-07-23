module OpenStreetMap
  module ActionMailer
    module MailDeliveryJob
      def perform(mailer, mail_method, delivery_method, *args, **kwargs)
        kwargs = args.pop if kwargs.empty? && args.last.is_a?(Hash)

        super(mailer, mail_method, delivery_method, *args, **kwargs)
      end
    end
  end
end

ActionMailer::MailDeliveryJob.prepend(OpenStreetMap::ActionMailer::MailDeliveryJob)
