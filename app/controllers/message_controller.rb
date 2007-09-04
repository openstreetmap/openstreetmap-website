class MessageController < ApplicationController
  layout 'site'

  before_filter :authorize_web
  before_filter :require_user

  def new
    @title = 'send message'
    if params[:message]
      @message = Message.new(params[:message])
      @message.to_user_id = params[:user_id]
      @message.from_user_id = @user.id
      @message.sent_on = Time.now
   
      if @message.save
        flash[:notice] = 'Message sent'
        redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
      end
    end
  end

  def read
    @title = 'read message'
    @message = Message.find(params[:message_id], :conditions => ["to_user_id = ?", @user.id])
    @message.message_read = 1
    @message.save
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => :not_found
  end

  def inbox
    @title = 'inbox'
    if @user and params[:display_name] == @user.display_name
    else
      redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
    end
  end

  def mark
    if params[:message_id]
      id = params[:message_id]
      message = Message.find_by_id(id)
      if params[:mark] == 'unread'
        message_read = 0 
        mark_type = 'unread'
      else
        message_read = 1
        mark_type = 'read'
      end
      message.message_read = message_read
      if message.save
        flash[:notice] = "Message marked as #{mark_type}"
        redirect_to :controller => 'message', :action => 'inbox', :display_name => @user.display_name
      end
    end
  end
end
