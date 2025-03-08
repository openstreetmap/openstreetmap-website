module Api
  module Users
    class TracesController < ApiController
      before_action :authorize

      authorize_resource :trace

      def index
        @traces = current_user.traces.reload
        respond_to do |format|
          format.xml { render :content_type => "application/xml" }
          format.json { render :content_type => "application/json" }
        end
      end
    end
  end
end
