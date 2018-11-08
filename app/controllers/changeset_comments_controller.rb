class ChangesetCommentsController < ApplicationController
  before_action :authorize_web, :only => [:index]
  before_action :set_locale, :only => [:index]
  before_action :authorize, :only => [:create, :destroy, :restore]
  before_action :require_moderator, :only => [:destroy, :restore]
  before_action :require_allow_write_api, :only => [:create, :destroy, :restore]
  before_action :require_public_data, :only => [:create]
  before_action :check_api_writable, :only => [:create, :destroy, :restore]
  before_action :check_api_readable, :except => [:create, :index]
  before_action(:only => [:index]) { |c| c.check_database_readable(true) }
  around_action :api_call_handle_error, :except => [:index]
  around_action :api_call_timeout, :except => [:index]
  around_action :web_timeout, :only => [:index]

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
    render :xml => changeset.to_xml.to_s
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
    render :xml => comment.changeset.to_xml.to_s
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
    render :xml => comment.changeset.to_xml.to_s
  end

  ##
  # Get a feed of recent changeset comments
  def index
    if params[:id]
      # Extract the arguments
      id = params[:id].to_i

      # Find the changeset
      changeset = Changeset.find(id)

      # Return comments for this changeset only
      @comments = changeset.comments.includes(:author, :changeset).limit(comments_limit)
    else
      # Return comments
      @comments = ChangesetComment.includes(:author, :changeset).where(:visible => true).order("created_at DESC").limit(comments_limit).preload(:changeset)
    end

    # Render the result
    respond_to do |format|
      format.rss
    end
  rescue OSM::APIBadUserInput
    head :bad_request
  end

  private

  ##
  # Get the maximum number of comments to return
  def comments_limit
    if params[:limit]
      if params[:limit].to_i.positive? && params[:limit].to_i <= 10000
        params[:limit].to_i
      else
        raise OSM::APIBadUserInput, "Comments limit must be between 1 and 10000"
      end
    else
      100
    end
  end
end
