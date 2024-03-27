module Traces
  class PicturesController < ApplicationController
    before_action :authorize_web
    before_action :check_database_readable

    authorize_resource :trace

    def show
      trace = Trace.find(params[:trace_id])

      if trace.visible? && trace.inserted?
        if trace.public? || (current_user && current_user == trace.user)
          if trace.icon.attached?
            redirect_to rails_blob_path(trace.image, :disposition => "inline")
          else
            expires_in 7.days, :private => !trace.public?, :public => trace.public?
            send_file(trace.large_picture_name, :filename => "#{trace.id}.gif", :type => "image/gif", :disposition => "inline")
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
