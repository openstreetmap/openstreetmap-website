# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetsController < ApplicationController
  layout "site"
  require "xml/libxml"

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }, :only => [:index, :feed]

  authorize_resource

  around_action :web_timeout

  # Helper methods for checking consistency
  include ConsistencyValidations

  ##
  # list non-empty changesets in reverse chronological order
  def index
    @params = params.permit(:display_name, :bbox, :fit_bbox, :friends, :nearby, :max_id, :list)

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
        changesets = conditions_bbox(changesets, BoundingBox.from_bbox_params(params), @params[:fit_bbox])
      elsif @params[:friends] && current_user
        changesets = changesets.where(:user_id => current_user.friends.identifiable)
      elsif @params[:nearby] && current_user
        changesets = changesets.where(:user_id => current_user.nearby)
      end

      changesets = changesets.where("changesets.id <= ?", @params[:max_id]) if @params[:max_id]

      @changesets = changesets.order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)

      render :action => :index, :layout => false
    end
  end

  ##
  # list edits as an atom feed
  def feed
    index
  end

  private

  #------------------------------------------------------------
  # utility functions below.
  #------------------------------------------------------------

  ##
  # The API has few situations, where parameter is supposed
  # to have boolean value (true/false), but previously their
  # values were ignored and script checked only null/not null
  # state.
  # If string value is true, return boolean true, otherwize false.
  def check_boolean(value)
    value.to_s.casecmp("true").zero?
  end

  ##
  # if a bounding box was specified do some sanity checks.
  # restrict changesets to those enclosed by a bounding box
  # alternatively only those chsets that are fully within bbox
  # we need to return both the changesets and the bounding box
  def conditions_bbox(changesets, bbox, fit_bbox)
    if bbox
      bbox.check_boundaries
      bbox = bbox.to_scaled

      if check_boolean(fit_bbox)
        changesets.where("min_lon > ? and max_lon < ? and min_lat > ? and max_lat < ?",
                         bbox.min_lon.to_i, bbox.max_lon.to_i,
                         bbox.min_lat.to_i, bbox.max_lat.to_i)
      else
        changesets.where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
                         bbox.max_lon.to_i, bbox.min_lon.to_i,
                         bbox.max_lat.to_i, bbox.min_lat.to_i)
      end
    else
      changesets
    end
  end

  ##
  # eliminate empty changesets (where the bbox has not been set)
  # this should be applied to all changeset list displays
  def conditions_nonempty(changesets)
    changesets.where("num_changes > 0")
  end
end
