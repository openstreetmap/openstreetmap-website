module Messages
  class MutesController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :message

    before_action :check_database_readable
    before_action :check_database_writable

    # Moves message into Inbox by unsetting the muted-flag
    def destroy
      message = current_user.muted_messages.find(params[:message_id])

      if message.unmute
        flash[:notice] = t(".notice")
      else
        flash[:error] = t(".error")
      end

      if current_user.muted_messages.none?
        redirect_to messages_inbox_path
      else
        redirect_to messages_muted_inbox_path
      end
    rescue ActiveRecord::RecordNotFound
      @title = t "messages.no_such_message.title"
      render :template => "messages/no_such_message", :status => :not_found
    end
  end
end
