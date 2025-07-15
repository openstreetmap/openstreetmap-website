module Api
  module OldElements
    class RedactionsController < ApiController
      before_action :check_api_writable
      before_action :authorize

      authorize_resource :class => :element_version_redaction

      before_action :lookup_old_element

      def create
        redaction_id = params["redaction"]
        if redaction_id
          redaction = Redaction.find(redaction_id.to_i)
          @old_element.redact!(redaction)
          head :ok
        elsif params["allow_delete"]
          # legacy unredact if no redaction ID was provided for /api/0.6/:element_type/:id/:version/redact paths mapped here
          destroy
        else
          raise OSM::APIBadUserInput, "No redaction was given" unless redaction_id
        end
      end

      def destroy
        @old_element.redact!(nil)
        head :ok
      end
    end
  end
end
