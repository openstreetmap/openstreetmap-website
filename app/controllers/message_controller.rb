class MessageController < ApplicationController
  layout 'site'
  #  before_filter :authorize
  before_filter :authorize_web
  before_filter :require_user

  def new
    @title = 'send message'
    if params[:message]
      to_user = User.find(params[:user_id])
      body = params[:message][:body]
      title = params[:message][:title]
      message = Message.new
      message.body = body
      message.title = title
      message.to_user_id = params[:user_id]
      message.from_display_name = to_user.display_name
      message.from_user_id = @user.id
      message.sent_on = Time.now
   
      if message.save
        flash[:notice] = 'Message sent'
        redirect_to :controller => 'user', :action => 'view', :display_name => @user.display_name
      else
        @message.errors.add("Sending message failed")
      end

    end
  end

  def read
    @title = 'read message'
    if params[:message_id]
      id = params[:message_id]
      @message = Message.find_by_id(id)
    end
  end

  def inbox
  end

  def mark
    if params[:message_id]
      id = params[:message_id]
      message = Message.find_by_id(id)
      message.message_read = 1
      if message.save
        flash[:notice] = 'Message Marked as read'
        redirect_to :controller => 'user', :action => 'view', :display_name => @user.display_name
      end
    end
  end
end
