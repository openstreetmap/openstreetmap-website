class MessagesController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user, :only => [:new, :create]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:new, :create, :destroy]

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
      redirect_to messages_outbox_path
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

      redirect_to referer || messages_inbox_path, :status => :see_other
    end
  rescue ActiveRecord::RecordNotFound
    @title = t "messages.no_such_message.title"
    render :action => "no_such_message", :status => :not_found
  end

  private

  ##
  # return permitted message parameters
  def message_params
    params.expect(:message => [:title, :body])
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new.permit(:title, :body)
  end
end
