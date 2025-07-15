module Api
  module ChangesetComments
    class VisibilitiesController < ApiController
      before_action :check_api_writable
      before_action :authorize

      authorize_resource :class => :changeset_comment_visibility

      before_action :set_request_formats

      ##
      # Sets visible flag on comment to true
      def create
        # Check the arguments are sane
        raise OSM::APIBadUserInput, "No id was given" unless params[:changeset_comment_id]

        # Extract the arguments
        changeset_comment_id = params[:changeset_comment_id].to_i

        # Find the changeset
        comment = ChangesetComment.find(changeset_comment_id)

        # Unhide the comment
        comment.update(:visible => true)

        # Return a copy of the updated changeset
        @changeset = comment.changeset

        respond_to do |format|
          format.xml
          format.json
        end
      end

      ##
      # Sets visible flag on comment to false
      def destroy
        # Check the arguments are sane
        raise OSM::APIBadUserInput, "No id was given" unless params[:changeset_comment_id]

        # Extract the arguments
        changeset_comment_id = params[:changeset_comment_id].to_i

        # Find the changeset
        comment = ChangesetComment.find(changeset_comment_id)

        # Hide the comment
        comment.update(:visible => false)

        # Return a copy of the updated changeset
        @changeset = comment.changeset

        respond_to do |format|
          format.xml
          format.json
        end
      end
    end
  end
end
