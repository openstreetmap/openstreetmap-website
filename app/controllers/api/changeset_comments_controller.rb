module Api
  class ChangesetCommentsController < ApiController
    before_action :authorize

    authorize_resource

    before_action :require_public_data, :only => [:create]
    before_action :check_api_writable
    before_action :check_api_readable, :except => [:create]
    around_action :api_call_handle_error
    around_action :api_call_timeout

    ##
    # Add a comment to a changeset
    def create
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]
      raise OSM::APIBadUserInput, "No text was given" if params[:text].blank?

      # Extract the arguments
      id = params[:id].to_i
      body = params[:text]

      # Find the changeset and check it is valid
      changeset = Changeset.find(id)
      raise OSM::APIChangesetNotYetClosedError, changeset if changeset.is_open?

      # Add a comment to the changeset
      comment = changeset.comments.create(:changeset => changeset,
                                          :body => body,
                                          :author => current_user)

      # Notify current subscribers of the new comment
      changeset.subscribers.visible.each do |user|
        Notifier.changeset_comment_notification(comment, user).deliver_later if current_user != user
      end

      # Add the commenter to the subscribers if necessary
      changeset.subscribers << current_user unless changeset.subscribers.exists?(current_user.id)

      # Return a copy of the updated changeset
      @changeset = changeset
      render "api/changesets/changeset"
    end

    ##
    # Sets visible flag on comment to false
    def destroy
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i

      # Find the changeset
      comment = ChangesetComment.find(id)

      # Hide the comment
      comment.update(:visible => false)

      # Return a copy of the updated changeset
      @changeset = comment.changeset
      render "api/changesets/changeset"
    end

    ##
    # Sets visible flag on comment to true
    def restore
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      # Extract the arguments
      id = params[:id].to_i

      # Find the changeset
      comment = ChangesetComment.find(id)

      # Unhide the comment
      comment.update(:visible => true)

      # Return a copy of the updated changeset
      @changeset = comment.changeset
      render "api/changesets/changeset"
    end
  end
end
