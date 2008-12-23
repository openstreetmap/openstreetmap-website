class MessageController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :require_user

  # Allow the user to write a new message to another user. This action also 
  # deals with the sending of that message to the other user when the user
  # clicks send.
  # The user_id param is the id of the user that the message is being sent to.
  def new
    @title = 'send message'
    @to_user = User.find(params[:user_id])
    if params[:message]
      @message = Message.new(params[:message])
      @message.to_user_id = @to_user.id
      @message.from_user_id = @user.id
      @message.sent_on = Time.now
   
      if @message.save
        flash[:notice] = 'Message sent'
        Notifier::deliver_message_notification(@message)
        redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
      end
    else
      @title = params[:title]
    end
  rescue ActiveRecord::RecordNotFound
    render :action => 'no_such_user', :status => :not_found
  end

  # Allow the user to reply to another message.
  def reply
    message = Message.find(params[:message_id], :conditions => ["to_user_id = ? or from_user_id = ?", @user.id, @user.id ])
    @body = "On #{message.sent_on} #{message.sender.display_name} wrote:\n\n#{message.body.gsub(/^/, '> ')}" 
    @title = "Re: #{message.title.sub(/^Re:\s*/, '')}"
    @user_id = message.from_user_id
    @to_user = User.find(message.to_user_id)
    render :action => 'new'
  rescue ActiveRecord::RecordNotFound
    render :action => 'no_such_user', :status => :not_found
  end

  # Show a message
  def read
    @title = 'read message'
    @message = Message.find(params[:message_id], :conditions => ["to_user_id = ? or from_user_id = ?", @user.id, @user.id ])
    @message.message_read = true if @message.to_user_id == @user.id
    @message.save
  rescue ActiveRecord::RecordNotFound
    render :action => 'no_such_user', :status => :not_found
  end

  # Display the list of messages that have been sent to the user.
  def inbox
    @title = 'inbox'
    if @user and params[:display_name] == @user.display_name
    else
      redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
    end
  end

  # Display the list of messages that the user has sent to other users.
  def outbox
    @title = 'outbox'
    if @user and params[:display_name] == @user.display_name
    else
      redirect_to :controller => 'message', :action => 'outbox', :display_name => @user.display_name
    end
  end

  # Set the message as being read or unread.
  def mark
    if params[:message_id]
      id = params[:message_id]
      message = Message.find_by_id(id)
      if params[:mark] == 'unread'
        message_read = false 
        mark_type = 'unread'
      else
        message_read = true
        mark_type = 'read'
      end
      message.message_read = message_read
      if message.save
        flash[:notice] = "Message marked as #{mark_type}"
        redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :action => 'no_such_user', :status => :not_found
  end
end
