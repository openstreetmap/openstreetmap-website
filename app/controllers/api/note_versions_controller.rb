module Api
  class NoteVersionsController < ApiController
    before_action :setup_user_auth

    authorize_resource

    before_action :set_request_formats

    def index
      # Retrieve all note versions
      @all_note_versions = NoteVersion.where(:note_id => params[:note_id]).order(:version)

      # Raise error if note's versions are not found
      raise OSM::APINotFoundError if @all_note_versions.empty?

      # If redacted notes should be displayed, continue using all note versions,
      # otherwise, continue using only note versions which are not redacted
      @note_versions = show_redactions? ? @all_note_versions : @all_note_versions.unredacted

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

      # If note version is reducted and we shouldn't display redacted note versions, return forbidden
      # otherwise, render the result
      if @note_version.redacted? && !show_redactions?
        head :forbidden
      else
        respond_to do |format|
          format.xml
          format.json
          format.gpx
        end
      end
    end

    private

    # Helper routine returning if redacted note versions should be displayed
    def show_redactions?
      current_user&.moderator? && params[:show_redactions] == "true"
    end
  end
end
