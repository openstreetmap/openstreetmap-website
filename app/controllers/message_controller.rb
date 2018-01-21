class MessageController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :require_user
  before_action :lookup_this_user, :only => [:new]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:new, :reply, :mark]
  before_action :allow_thirdparty_images, :only => [:new, :read]

  # Allow the user to write a new message to another user. This action also
  # deals with the sending of that message to the other user when the user
  # clicks send.
  # The display_name param is the display name of the user that the message is being sent to.
  def new
    if request.post?
      if current_user.sent_messages.where("sent_on >= ?", Time.now.getutc - 1.hour).count >= MAX_MESSAGES_PER_HOUR
        flash[:error] = t "message.new.limit_exceeded"
      else
        @message = Message.new(message_params)
        @message.recipient = @this_user
        @message.sender = current_user
        @message.sent_on = Time.now.getutc

        if @message.save
          flash[:notice] = t "message.new.message_sent"
          Notifier.message_notification(@message).deliver_now
          redirect_to :action => "inbox", :display_name => current_user.display_name
        end
      end
    end

    @message ||= Message.new(message_params.merge(:recipient => @this_user))
    @title = t "message.new.title"
  end

  # Allow the user to reply to another message.
  def reply
    message = Message.find(params[:message_id])

    if message.recipient == current_user
      message.update(:message_read => true)

      @message = Message.new(
        :recipient => message.sender,
        :title => "Re: #{message.title.sub(/^Re:\s*/, '')}",
        :body => "On #{message.sent_on} #{message.sender.display_name} wrote:\n\n#{message.body.gsub(/^/, '> ')}"
      )

      @title = @message.title

      render :action => "new"
    else
      flash[:notice] = t "message.reply.wrong_user", :user => current_user.display_name
      redirect_to :controller => "user", :action => "login", :referer => request.fullpath
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "message.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Show a message
  def read
    @title = t "message.read.title"
    @message = Message.find(params[:message_id])

    if @message.recipient == current_user || @message.sender == current_user
      @message.message_read = true if @message.recipient == current_user
      @message.save
    else
      flash[:notice] = t "message.read.wrong_user", :user => current_user.display_name
      redirect_to :controller => "user", :action => "login", :referer => request.fullpath
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "message.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Display the list of messages that have been sent to the user.
  def inbox
    @title = t "message.inbox.title"
    if current_user && params[:display_name] == current_user.display_name
    else
      redirect_to :action => "inbox", :display_name => current_user.display_name
    end
  end

  # Display the list of messages that the user has sent to other users.
  def outbox
    @title = t "message.outbox.title"
    if current_user && params[:display_name] == current_user.display_name
    else
      redirect_to :action => "outbox", :display_name => current_user.display_name
    end
  end

  # Set the message as being read or unread.
  def mark
    @message = Message.where("to_user_id = ? OR from_user_id = ?", current_user.id, current_user.id).find(params[:message_id])
    if params[:mark] == "unread"
      message_read = false
      notice = t "message.mark.as_unread"
    else
      message_read = true
      notice = t "message.mark.as_read"
    end
    @message.message_read = message_read
    if @message.save && !request.xhr?
      flash[:notice] = notice
      redirect_to :action => "inbox", :display_name => current_user.display_name
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "message.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Delete the message.
  def delete
    @message = Message.where("to_user_id = ? OR from_user_id = ?", current_user.id, current_user.id).find(params[:message_id])
    @message.from_user_visible = false if @message.sender == current_user
    @message.to_user_visible = false if @message.recipient == current_user
    if @message.save && !request.xhr?
      flash[:notice] = t "message.delete.deleted"

      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :action => "inbox", :display_name => current_user.display_name
      end
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "message.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  private

  ##
  # return permitted message parameters
  def message_params
    params.require(:message).permit(:title, :body)
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new.permit(:title, :body)
  end
end
