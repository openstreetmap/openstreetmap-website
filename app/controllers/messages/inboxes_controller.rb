module Messages
  class InboxesController < MailboxesController
    # Display the list of messages that have been sent to the user.
    def show
      @title = t ".title"
    end
  end
end
