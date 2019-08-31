class ChangesetCommentsController < ApplicationController
  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action -> { check_database_readable(true) }
  around_action :web_timeout

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
