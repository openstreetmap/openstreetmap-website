module Api
  module Messages
    class OutboxesController < MailboxesController
      def show
        @skip_body = true
        @messages = Message.includes(:sender, :recipient).where(:from_user_id => current_user.id)

        show_messages
      end
    end
  end
end
