module Api
  class NoteCommentsController < ApiController
    before_action :authorize

    authorize_resource

    before_action :check_api_writable
    before_action :check_api_readable
    around_action :api_call_handle_error
    around_action :api_call_timeout

    ##
    # Sets visible flag on note comment to false
    def destroy
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i

      # Find the note comment
      comment = NoteComment.find(id)

      # Opening comment cannot be hidden
      raise OSM::APIBadUserInput, "Cannot hide id" if comment.event == "opened"

      # Hide the comment
      comment.update(:visible => false)

      # Return a copy of the updated note
      @note = comment.note
      render(@note)
    end

    ##
    # Sets visible flag on note comment to true
    def restore
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i

      # Find the note comment
      comment = NoteComment.find(id)

      # Opening comment cannot be unhidden
      raise OSM::APIBadUserInput, "Cannot unhide id" if comment.event == "opened"

      # Unhide the comment
      comment.update(:visible => true)

      # Return a copy of the updated note
      @note = comment.note
      render(@note)
    end
  end
end
