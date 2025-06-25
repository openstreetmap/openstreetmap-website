module Api
  module Messages
    class InboxesController < MailboxesController
      def show
        @skip_body = true
        @messages = Message.includes(:sender, :recipient).where(:to_user_id => current_user.id)

        show_messages
      end
    end
  end
end
