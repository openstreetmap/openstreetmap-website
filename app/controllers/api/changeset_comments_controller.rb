module Api
  class ChangesetCommentsController < ApiController
    include QueryMethods

    before_action :check_api_writable, :except => [:index]
    before_action :authorize, :except => [:index]

    authorize_resource

    before_action :require_public_data, :only => [:create]

    before_action :set_request_formats

    ##
    # show all comments or search for a subset
    def index
      @comments = ChangesetComment.includes(:author).where(:visible => true).order("created_at DESC")
      @comments = query_conditions_time(@comments)
      @comments = query_conditions_user(@comments, :author)
      @comments = query_limit(@comments)
    end

    ##
    # Add a comment to a changeset
    def create
      # Check the arguments are sane
      raise OSM::APIBadUserInput, "No id was given" unless params[:changeset_id]
      raise OSM::APIBadUserInput, "No text was given" if params[:text].blank?
      raise OSM::APIRateLimitExceeded if rate_limit_exceeded?

      # Extract the arguments
      changeset_id = params[:changeset_id].to_i
      body = params[:text]

      # Find the changeset and check it is valid
      changeset = Changeset.find(changeset_id)
      raise OSM::APIChangesetNotYetClosedError, changeset if changeset.open?

      # Add a comment to the changeset
      comment = changeset.comments.create(:changeset => changeset,
                                          :body => body,
                                          :author => current_user)

      # Notify current subscribers of the new comment
      changeset.subscribers.visible.each do |user|
        UserMailer.changeset_comment_notification(comment, user).deliver_later if current_user != user
      end

      # Add the commenter to the subscribers if necessary
      changeset.subscribers << current_user unless changeset.subscribers.exists?(current_user.id)

      # Return a copy of the updated changeset
      @changeset = changeset
      render "api/changesets/show"

      respond_to do |format|
        format.xml
        format.json
      end
    end

    private

    ##
    # Check if the current user has exceed the rate limit for comments
    def rate_limit_exceeded?
      recent_comments = current_user.changeset_comments.where(:created_at => Time.now.utc - 1.hour..).count

      recent_comments >= current_user.max_changeset_comments_per_hour
    end
  end
end
