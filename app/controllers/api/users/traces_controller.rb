module Api
  module Users
    class TracesController < ApiController
      before_action :authorize

      authorize_resource :trace

      def index
        @traces = current_user.traces.reload
        render :content_type => "application/xml"
      end
    end
  end
end
