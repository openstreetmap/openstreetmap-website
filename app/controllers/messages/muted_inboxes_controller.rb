module Messages
  class MutedInboxesController < MailboxesController
    # Display the list of muted messages received by the user.
    def show
      @title = t ".title"

      redirect_to messages_inbox_path if current_user.muted_messages.none?
    end
  end
end
