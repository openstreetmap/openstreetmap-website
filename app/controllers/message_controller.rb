class MessageController < ApplicationController
  layout 'site'
  #  before_filter :authorize
  before_filter :authorize_web
  before_filter :require_user

  def new
    if params[:message]
      body = params[:message][:body]
      title = params[:message][:title]
      message = Message.new
      message.body = body
      message.title = title
      message.to_user_id = User.find_by_display_name(params[:display_name]).id
      message.from_user_id = @user.id
      message.sent_on = Time.now
      if message.save
        flash[:notice] = 'Message sent'
      else
        @message.errors.add("Sending message failed")
      end
      
   end
  end
end
