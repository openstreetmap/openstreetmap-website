module Api
  class NoteVersionsController < ApiController
    before_action :setup_user_auth

    authorize_resource

    before_action :set_request_formats

    def show
      # Retrieve appropriate note's version
      @note_version = NoteVersion.find([params[:note_id], params[:version]])

      # Render the result
      respond_to do |format|
        format.xml
        format.json
        format.gpx
      end
    end
  end
end
