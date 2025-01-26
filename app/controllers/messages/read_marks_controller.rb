module Messages
  class ReadMarksController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :message

    before_action :check_database_readable
    before_action :check_database_writable

    def create
      mark true
    end

    def destroy
      mark false
    end

    private

    def mark(message_read)
      @message = current_user.messages.unscope(:where => :muted).find(params[:message_id])
      @message.message_read = message_read
      if @message.save
        flash[:notice] = t ".notice"
        if @message.muted?
          redirect_to messages_muted_inbox_path, :status => :see_other
        else
          redirect_to messages_inbox_path, :status => :see_other
        end
      end
    rescue ActiveRecord::RecordNotFound
      @title = t "messages.no_such_message.title"
      render :template => "messages/no_such_message", :status => :not_found
    end
  end
end
