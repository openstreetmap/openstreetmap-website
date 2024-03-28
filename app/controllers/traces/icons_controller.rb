module Traces
  class IconsController < ApplicationController
    before_action :authorize_web
    before_action :check_database_readable

    authorize_resource :trace

    def show
      trace = Trace.visible.find(params[:trace_id])

      if trace.inserted?
        if trace.public? || (current_user && current_user == trace.user)
          if trace.icon.attached?
            redirect_to rails_blob_path(trace.icon, :disposition => "inline")
          else
            expires_in 7.days, :private => !trace.public?, :public => trace.public?
            send_file(trace.icon_picture_name, :filename => "#{trace.id}_icon.gif", :type => "image/gif", :disposition => "inline")
          end
        else
          head :forbidden
        end
      else
        head :not_found
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end
end
