class ChangesetCommentsController < ApplicationController
  include QueryMethods

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action -> { check_database_readable(:need_api => true) }
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
      @comments = changeset.comments.includes(:author, :changeset)
      @comments = query_limit(@comments)
    else
      # Return comments
      @comments = ChangesetComment.includes(:author, :changeset).where(:visible => true).order("created_at DESC")
      @comments = query_limit(@comments)
      @comments = @comments.preload(:changeset)
    end

    # Render the result
    respond_to do |format|
      format.rss
    end
  rescue OSM::APIBadUserInput
    head :bad_request
  end
end
