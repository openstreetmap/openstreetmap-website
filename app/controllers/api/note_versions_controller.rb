module Api
  class NoteVersionsController < ApiController
    before_action :setup_user_auth

    authorize_resource

    before_action :set_request_formats

    def index
      # Retrieve all note versions
      @note_versions = NoteVersion.where(:note_id => params[:note_id]).order(:version)

      # Render the result
      respond_to do |format|
        format.xml
        format.json
        format.gpx
      end
    end

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
