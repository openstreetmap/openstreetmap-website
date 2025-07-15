module Messages
  class RepliesController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => Message

    before_action :check_database_readable
    before_action :check_database_writable

    allow_thirdparty_images

    # Allow the user to reply to another message.
    def new
      message = Message.find(params[:message_id])

      if message.recipient == current_user
        message.update(:message_read => true)

        @message = Message.new(
          :recipient => message.sender,
          :title => "Re: #{message.title.sub(/^Re:\s*/, '')}",
          :body => "On #{message.sent_on} #{message.sender.display_name} wrote:\n\n#{message.body.gsub(/^/, '> ')}"
        )

        @title = @message.title

        render "messages/new"
      elsif message.sender == current_user
        @message = Message.new(
          :recipient => message.recipient,
          :title => "Re: #{message.title.sub(/^Re:\s*/, '')}",
          :body => "On #{message.sent_on} #{message.sender.display_name} wrote:\n\n#{message.body.gsub(/^/, '> ')}"
        )

        @title = @message.title

        render "messages/new"
      else
        flash[:notice] = t ".wrong_user", :user => current_user.display_name
        redirect_to login_path(:referer => request.fullpath)
      end
    rescue ActiveRecord::RecordNotFound
      @title = t "messages.no_such_message.title"
      render "messages/no_such_message", :status => :not_found
    end
  end
end
