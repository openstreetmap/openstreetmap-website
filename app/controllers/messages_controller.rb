class MessagesController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user, :only => [:new, :create]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:new, :create, :reply, :mark, :destroy]

  allow_thirdparty_images :only => [:new, :create, :show]

  # Show a message
  def show
    @title = t ".title"
    @message = Message.find(params[:id])

    if @message.recipient == current_user || @message.sender == current_user
      @message.message_read = true if @message.recipient == current_user
      @message.save
    else
      flash[:notice] = t ".wrong_user", :user => current_user.display_name
      redirect_to login_path(:referer => request.fullpath)
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Allow the user to write a new message to another user.
  def new
    @message = Message.new(message_params.merge(:recipient => @user))
    @title = t ".title"
  end

  def create
    @message = Message.new(message_params)
    @message.recipient = @user
    @message.sender = current_user
    @message.sent_on = Time.now.utc

    if current_user.sent_messages.where(:sent_on => Time.now.utc - 1.hour..).count >= current_user.max_messages_per_hour
      flash.now[:error] = t ".limit_exceeded"
      render :action => "new"
    elsif @message.save
      flash[:notice] = t ".message_sent"
      UserMailer.message_notification(@message).deliver_later if @message.notify_recipient?
      redirect_to :action => :inbox
    else
      @title = t "messages.new.title"
      render :action => "new"
    end
  end

  # Destroy the message.
  def destroy
    @message = Message.where(:recipient => current_user).or(Message.where(:sender => current_user.id)).find(params[:id])
    @message.from_user_visible = false if @message.sender == current_user
    @message.to_user_visible = false if @message.recipient == current_user
    if @message.save
      flash[:notice] = t ".destroyed"

      referer = safe_referer(params[:referer]) if params[:referer]

      redirect_to referer || { :action => :inbox }, :status => :see_other
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
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
    elsif message.sender == current_user
      @message = Message.new(
        :recipient => message.recipient,
        :title => "Re: #{message.title.sub(/^Re:\s*/, '')}",
        :body => "On #{message.sent_on} #{message.sender.display_name} wrote:\n\n#{message.body.gsub(/^/, '> ')}"
      )

      @title = @message.title

      render :action => "new"
    else
      flash[:notice] = t ".wrong_user", :user => current_user.display_name
      redirect_to login_path(:referer => request.fullpath)
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

  # Display the list of muted messages received by the user.
  def muted
    @title = t ".title"

    redirect_to inbox_messages_path if current_user.muted_messages.none?
  end

  # Set the message as being read or unread.
  def mark
    @message = current_user.messages.unscope(:where => :muted).find(params[:message_id])
    if params[:mark] == "unread"
      message_read = false
      notice = t ".as_unread"
    else
      message_read = true
      notice = t ".as_read"
    end
    @message.message_read = message_read
    if @message.save
      flash[:notice] = notice
      if @message.muted?
        redirect_to muted_messages_path, :status => :see_other
      else
        redirect_to inbox_messages_path, :status => :see_other
      end
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  # Moves message into Inbox by unsetting the muted-flag
  def unmute
    message = current_user.muted_messages.find(params[:message_id])

    if message.unmute
      flash[:notice] = t(".notice")
    else
      flash[:error] = t(".error")
    end

    if current_user.muted_messages.none?
      redirect_to inbox_messages_path
    else
      redirect_to muted_messages_path
    end
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
