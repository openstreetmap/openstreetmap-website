module Traces
  class PicturesController < ApplicationController
    before_action :authorize_web
    before_action :check_database_readable

    authorize_resource :trace

    def show
      trace = Trace.visible.imported.find(params[:trace_id])

      if trace.public? || (current_user && current_user == trace.user)
        redirect_to rails_blob_path(trace.image, :disposition => "inline")
      else
        head :forbidden
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end
end
