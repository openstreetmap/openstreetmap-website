module Messages
  class OutboxesController < MailboxesController
    # Display the list of messages that the user has sent to other users.
    def show
      @title = t ".title"
    end
  end
end
