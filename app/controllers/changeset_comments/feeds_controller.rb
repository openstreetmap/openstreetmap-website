module ChangesetComments
  class FeedsController < ApplicationController
    include QueryMethods

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :changeset_comment

    before_action -> { check_database_readable(:need_api => true) }
    around_action :web_timeout

    ##
    # Get a feed of recent changeset comments
    def show
      if params[:changeset_id]
        # Extract the arguments
        changeset_id = params[:changeset_id].to_i

        # Find the changeset
        changeset = Changeset.find(changeset_id)

        # Return comments for this changeset only
        @comments = changeset.comments.includes(:author, :changeset).reverse_order
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
end
