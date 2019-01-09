class MessagesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user, :only => [:new, :create]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:new, :create, :reply, :mark, :destroy]
  before_action :allow_thirdparty_images, :only => [:new, :create, :show]

  # Allow the user to write a new message to another user. This action also
  # deals with the sending of that message to the other user when the user
  # clicks send.
  # The display_name param is the display name of the user that the message is being sent to.
  def new
    @message = Message.new(message_params.merge(:recipient => @user))
    @title = t ".title"
  end

  def create
    @message = Message.new(message_params)
    @message.recipient = @user
    @message.sender = current_user
    @message.sent_on = Time.now.getutc

    if current_user.sent_messages.where("sent_on >= ?", Time.now.getutc - 1.hour).count >= MAX_MESSAGES_PER_HOUR
      flash[:error] = t ".limit_exceeded"
      render :action => "new"
    elsif @message.save
      flash[:notice] = t ".message_sent"
      Notifier.message_notification(@message).deliver_later
      redirect_to :action => :inbox
    else
      render :action => "new"
    end
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
      flash[:notice] = t ".wrong_user", :user => current_user.display_name
      redirect_to :controller => "users", :action => "login", :referer => request.fullpath
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Show a message
  def show
    @title = t ".title"
    @message = Message.find(params[:id])

    if @message.recipient == current_user || @message.sender == current_user
      @message.message_read = true if @message.recipient == current_user
      @message.save
    else
      flash[:notice] = t ".wrong_user", :user => current_user.display_name
      redirect_to :controller => "users", :action => "login", :referer => request.fullpath
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Display the list of messages that have been sent to the user.
  def inbox
    @title = t ".title"
  end

  # Display the list of messages that the user has sent to other users.
  def outbox
    @title = t ".title"
  end

  # Set the message as being read or unread.
  def mark
    @message = Message.where("to_user_id = ? OR from_user_id = ?", current_user.id, current_user.id).find(params[:message_id])
    if params[:mark] == "unread"
      message_read = false
      notice = t ".as_unread"
    else
      message_read = true
      notice = t ".as_read"
    end
    @message.message_read = message_read
    if @message.save && !request.xhr?
      flash[:notice] = notice
      redirect_to :action => :inbox
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Destroy the message.
  def destroy
    @message = Message.where("to_user_id = ? OR from_user_id = ?", current_user.id, current_user.id).find(params[:id])
    @message.from_user_visible = false if @message.sender == current_user
    @message.to_user_visible = false if @message.recipient == current_user
    if @message.save && !request.xhr?
      flash[:notice] = t ".destroyed"

      if params[:referer]
        redirect_to params[:referer]
      else
        redirect_to :action => :inbox
      end
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
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
