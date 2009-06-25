class MessageController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :set_locale
  before_filter :require_user
  before_filter :check_database_readable
  before_filter :check_database_writable, :only => [:new, :reply, :mark]

  # Allow the user to write a new message to another user. This action also 
  # deals with the sending of that message to the other user when the user
  # clicks send.
  # The display_name param is the display name of the user that the message is being sent to.
  def new
    @to_user = User.find_by_display_name(params[:display_name])
    if @to_user
      if params[:message]
        @message = Message.new(params[:message])
        @message.to_user_id = @to_user.id
        @message.from_user_id = @user.id
        @message.sent_on = Time.now.getutc

        if @message.save
          flash[:notice] = t 'message.new.message_sent'
          Notifier::deliver_message_notification(@message)
          redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
        end
      else
        if params[:title]
          # ?title= is set when someone reponds to this user's diary entry
          @title = params[:title]
        else
          # The default /message/new/$user view
          @title = t 'message.new.title'
        end
      end
    else
      @title = t'message.no_such_user.title'
      render :action => 'no_such_user', :status => :not_found
    end
  end

  # Allow the user to reply to another message.
  def reply
    message = Message.find(params[:message_id], :conditions => ["to_user_id = ? or from_user_id = ?", @user.id, @user.id ])
    @body = "On #{message.sent_on} #{message.sender.display_name} wrote:\n\n#{message.body.gsub(/^/, '> ')}" 
    @title = "Re: #{message.title.sub(/^Re:\s*/, '')}"
    @to_user = User.find(message.from_user_id)
    render :action => 'new'
  rescue ActiveRecord::RecordNotFound
    @title = t'message.no_such_user.title'
    render :action => 'no_such_user', :status => :not_found
  end

  # Show a message
  def read
    @title = t 'message.read.title'
    @message = Message.find(params[:message_id], :conditions => ["to_user_id = ? or from_user_id = ?", @user.id, @user.id ])
    @message.message_read = true if @message.to_user_id == @user.id
    @message.save
  rescue ActiveRecord::RecordNotFound
    @title = t'message.no_such_user.title'
    render :action => 'no_such_user', :status => :not_found
  end

  # Display the list of messages that have been sent to the user.
  def inbox
    @title = t 'message.inbox.title'
    if @user and params[:display_name] == @user.display_name
    else
      redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
    end
  end

  # Display the list of messages that the user has sent to other users.
  def outbox
    @title = t 'message.outbox.title'
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
        notice = t 'message.mark.as_unread'
      else
        message_read = true
        notice = t 'message.mark.as_read'
      end
      message.message_read = message_read
      if message.save
        flash[:notice] = notice
        redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
      end
    end
  rescue ActiveRecord::RecordNotFound
    @title = t'message.no_such_user.title'
    render :action => 'no_such_user', :status => :not_found
  end
end
