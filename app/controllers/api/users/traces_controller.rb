# frozen_string_literal: true

module Api
  module Users
    class TracesController < ApiController
      before_action :authorize
      before_action :set_request_formats

      authorize_resource :trace

      def index
        @traces = current_user.traces.reload
        respond_to do |format|
          format.xml
          format.json
        end
      end
    end
  end
end
