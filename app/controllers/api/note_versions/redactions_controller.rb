module Api
  module NoteVersions
    class RedactionsController < ApiController
      before_action :check_api_writable
      before_action :authorize

      authorize_resource :class => :element_version_redaction

      def create
        # Find note version for which we want to create redaction
        note_version = NoteVersion.find([params[:note_id], params[:version]])

        # Create redaction for specified note version
        redaction_id = params["redaction"]
        if redaction_id
          redaction = Redaction.find(redaction_id.to_i)
          note_version.redact!(redaction)
          head :ok
        elsif params["allow_delete"]
          # legacy unredact if no redaction ID was provided for /api/0.6/:element_type/:id/:version/redact paths mapped here
          destroy
        else
          raise OSM::APIBadUserInput, "No redaction was given" unless redaction_id
        end
      end

      def destroy
        # Find note version for which we want to destroy redaction
        note_version = NoteVersion.find([params[:note_id], params[:version]])

        # Destroy redaction for note version
        note_version.redact!(nil)
        head :ok
      end
    end
  end
end
