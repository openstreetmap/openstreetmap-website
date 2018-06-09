class ChangesetController < ApplicationController
  layout "site"
  require "xml/libxml"

  skip_before_action :verify_authenticity_token, :except => [:list]
  before_action :authorize_web, :only => [:list, :feed, :comments_feed]
  before_action :set_locale, :only => [:list, :feed, :comments_feed]
  before_action(:only => [:list, :feed, :comments_feed]) { |c| c.check_database_readable(true) }
  around_action :web_timeout, :only => [:list, :feed, :comments_feed]

  include Changesetable

  ##
  # list non-empty changesets in reverse chronological order
  def list
    @params = params.permit(:display_name, :bbox, :friends, :nearby, :max_id, :list)

    if request.format == :atom && @params[:max_id]
      redirect_to url_for(@params.merge(:max_id => nil)), :status => :moved_permanently
      return
    end

    if @params[:display_name]
      user = User.find_by(:display_name => @params[:display_name])
      if !user || !user.active?
        render_unknown_user @params[:display_name]
        return
      end
    end

    if (@params[:friends] || @params[:nearby]) && !current_user
      require_user
      return
    end

    if request.format == :html && !@params[:list]
      require_oauth
      render :action => :history, :layout => map_layout
    else
      changesets = conditions_nonempty(Changeset.all)

      if @params[:display_name]
        changesets = if user.data_public? || user == current_user
                       changesets.where(:user_id => user.id)
                     else
                       changesets.where("false")
                     end
      elsif @params[:bbox]
        changesets = conditions_bbox(changesets, BoundingBox.from_bbox_params(params))
      elsif @params[:friends] && current_user
        changesets = changesets.where(:user_id => current_user.friend_users.identifiable)
      elsif @params[:nearby] && current_user
        changesets = changesets.where(:user_id => current_user.nearby)
      end

      changesets = changesets.where("changesets.id <= ?", @params[:max_id]) if @params[:max_id]

      @edits = changesets.order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)

      render :action => :list, :layout => false
    end
  end

  ##
  # list edits as an atom feed
  def feed
    list
  end

  ##
  # Get a feed of recent changeset comments
  def comments_feed
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
end
