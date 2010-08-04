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
        if @user.sent_messages.count(:conditions => ["sent_on >= ?", Time.now.getutc - 1.hour]) >= MAX_MESSAGES_PER_HOUR
          flash[:error] = t 'message.new.limit_exceeded'
        else
          @message = Message.new(params[:message])
          @message.to_user_id = @to_user.id
          @message.from_user_id = @user.id
          @message.sent_on = Time.now.getutc

          if @message.save
            flash[:notice] = t 'message.new.message_sent'
            Notifier::deliver_message_notification(@message)
            redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
          end
        end
      else
        if params[:title]
          # ?title= is set when someone reponds to this user's diary
          # entry. Then we pre-fill out the subject and the <title>
          @title = @subject = params[:title]
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
    message = Message.find(params[:message_id])

    if message.to_user_id == @user.id then
      @body = "On #{message.sent_on} #{message.sender.display_name} wrote:\n\n#{message.body.gsub(/^/, '> ')}" 
      @title = @subject = "Re: #{message.title.sub(/^Re:\s*/, '')}"
      @to_user = User.find(message.from_user_id)

      render :action => 'new'
    else
      flash[:notice] = t 'message.reply.wrong_user', :user => @user.display_name
      redirect_to :controller => "user", :action => "login", :referer => request.request_uri
    end
  rescue ActiveRecord::RecordNotFound
    @title = t'message.no_such_message.title'
    render :action => 'no_such_message', :status => :not_found
  end

  # Show a message
  def read
    @title = t 'message.read.title'
    @message = Message.find(params[:message_id])

    if @message.to_user_id == @user.id or @message.from_user_id == @user.id then
      @message.message_read = true if @message.to_user_id == @user.id
      @message.save
    else
      flash[:notice] = t 'message.read.wrong_user', :user => @user.display_name
      redirect_to :controller => "user", :action => "login", :referer => request.request_uri
    end
  rescue ActiveRecord::RecordNotFound
    @title = t'message.no_such_message.title'
    render :action => 'no_such_message', :status => :not_found
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
      message = Message.find_by_id(id, :conditions => ["to_user_id = ? or from_user_id = ?", @user.id, @user.id])
      if params[:mark] == 'unread'
        message_read = false 
        notice = t 'message.mark.as_unread'
      else
        message_read = true
        notice = t 'message.mark.as_read'
      end
      message.message_read = message_read
      if message.save
        if request.xhr?
          render :update do |page|
            page.replace "inboxanchor", :partial => "layouts/inbox"
            page.replace "inbox-count", :partial => "message_count"
            page.replace "inbox-#{message.id}", :partial => "message_summary", :object => message
          end
        else
          flash[:notice] = notice
          redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    @title = t'message.no_such_message.title'
    render :action => 'no_such_message', :status => :not_found
  end

  # Delete the message.
  def delete
    if params[:message_id]
      id = params[:message_id]
      message = Message.find_by_id(id, :conditions => ["to_user_id = ? or from_user_id = ?", @user.id, @user.id])
      message.from_user_visible = false if message.sender == @user
      message.to_user_visible = false if message.recipient == @user
      if message.save
        flash[:notice] = t 'message.delete.deleted'

        if params[:referer]
          redirect_to params[:referer]
        else
          redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    @title = t'message.no_such_message.title'
    render :action => 'no_such_message', :status => :not_found
  end
end
