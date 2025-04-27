# frozen_string_literal: true

# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetsController < ApplicationController
  include UserMethods
  include PaginationMethods

  layout :site_layout

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth, :only => :show

  authorize_resource

  around_action :web_timeout

  ELEMENTS_PER_PAGE = 20

  ##
  # list non-empty changesets in reverse chronological order
  def index
    param! :before, Integer, :min => 1
    param! :after, Integer, :min => 1

    @params = params.permit(:display_name, :bbox, :friends, :nearby, :before, :after, :list)

    if request.format == :atom && (@params[:before] || @params[:after])
      redirect_to url_for(@params.merge(:before => nil, :after => nil)), :status => :moved_permanently
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
                       changesets.where(:user => user)
                     else
                       changesets.where("false")
                     end
      elsif @params[:bbox]
        bbox_array = @params[:bbox].split(",").map(&:to_f)
        raise OSM::APIBadUserInput, "The parameter bbox must be of the form min_lon,min_lat,max_lon,max_lat" unless bbox_array.count == 4

        changesets = conditions_bbox(changesets, *bbox_array)
      elsif @params[:friends] && current_user
        changesets = changesets.where(:user => current_user.followings.identifiable)
      elsif @params[:nearby] && current_user
        changesets = changesets.where(:user => current_user.nearby)
      end

      @changesets, @newer_changesets_id, @older_changesets_id = get_page_items(changesets, :includes => [:user, :changeset_tags, :comments])

      render :action => :index, :layout => false
    end
  end

  ##
  # list edits as an atom feed
  def feed
    index
  end

  def show
    @type = "changeset"
    @changeset = Changeset.find(params[:id])
    case turbo_frame_request_id
    when "changeset_nodes"
      load_nodes
      render :partial => "elements", :locals => { :type => "node", :elements => @nodes, :elements_count => @nodes_count, :current_page => @current_node_page }
    when "changeset_ways"
      load_ways
      render :partial => "elements", :locals => { :type => "way", :elements => @ways, :elements_count => @ways_count, :current_page => @current_way_page }
    when "changeset_relations"
      load_relations
      render :partial => "elements", :locals => { :type => "relation", :elements => @relations, :elements_count => @relations_count, :current_page => @current_relation_page }
    else
      @comments = if current_user&.moderator?
                    @changeset.comments.unscope(:where => :visible).includes(:author)
                  else
                    @changeset.comments.includes(:author)
                  end
      load_nodes
      load_ways
      load_relations
      if @changeset.user.active? && @changeset.user.data_public?
        changesets = conditions_nonempty(@changeset.user.changesets)
        @next_by_user = changesets.where("id > ?", @changeset.id).reorder(:id => :asc).first
        @prev_by_user = changesets.where(:id => ...@changeset.id).reorder(:id => :desc).first
      end
      render :layout => map_layout
    end
  rescue ActiveRecord::RecordNotFound
    render :template => "browse/not_found", :status => :not_found, :layout => map_layout
  end

  private

  #------------------------------------------------------------
  # utility functions below.
  #------------------------------------------------------------

  ##
  # restrict changesets to those enclosed by a bounding box
  def conditions_bbox(changesets, min_lon, min_lat, max_lon, max_lat)
    db_min_lat = (min_lat * GeoRecord::SCALE).to_i
    db_max_lat = (max_lat * GeoRecord::SCALE).to_i
    db_min_lon = (wrap_lon(min_lon) * GeoRecord::SCALE).to_i
    db_max_lon = (wrap_lon(max_lon) * GeoRecord::SCALE).to_i

    changesets = changesets.where("min_lat < ? and max_lat > ?", db_max_lat, db_min_lat)

    if max_lon - min_lon >= 360
      # the query bbox spans the entire world, therefore no lon checks are necessary
      changesets
    elsif db_min_lon <= db_max_lon
      # the normal case when the query bbox doesn't include the antimeridian
      changesets.where("min_lon < ? and max_lon > ?", db_max_lon, db_min_lon)
    else
      # the query bbox includes the antimeridian
      # this case works as if there are two query bboxes:
      #   [-180*SCALE .. db_max_lon], [db_min_lon .. 180*SCALE]
      # it would be necessary to check if changeset bboxes intersect with either of the query bboxes:
      #   (changesets.min_lon < db_max_lon and changesets.max_lon > -180*SCALE) or (changesets.min_lon < 180*SCALE and changesets.max_lon > db_min_lon)
      # but the comparisons with -180*SCALE and 180*SCALE are unnecessary:
      #   (changesets.min_lon < db_max_lon) or (changesets.max_lon > db_min_lon)
      changesets.where("min_lon < ? or max_lon > ?", db_max_lon, db_min_lon)
    end
  end

  def wrap_lon(lon)
    ((lon + 180) % 360) - 180
  end

  ##
  # eliminate empty changesets (where the bbox has not been set)
  # this should be applied to all changeset list displays
  def conditions_nonempty(changesets)
    changesets.where("num_changes > 0")
  end

  def load_nodes
    @nodes_count = @changeset.actual_num_changed_nodes
    @current_node_page = params[:node_page].to_i.clamp(1, element_pages_count(@nodes_count))
    @nodes = @changeset.old_nodes
                       .order(:node_id, :version)
                       .offset(ELEMENTS_PER_PAGE * (@current_node_page - 1))
                       .limit(ELEMENTS_PER_PAGE)
  end

  def load_ways
    @ways_count = @changeset.actual_num_changed_ways
    @current_way_page = params[:way_page].to_i.clamp(1, element_pages_count(@ways_count))
    @ways = @changeset.old_ways
                      .order(:way_id, :version)
                      .offset(ELEMENTS_PER_PAGE * (@current_way_page - 1))
                      .limit(ELEMENTS_PER_PAGE)
  end

  def load_relations
    @relations_count = @changeset.actual_num_changed_relations
    @current_relation_page = params[:relation_page].to_i.clamp(1, element_pages_count(@relations_count))
    @relations = @changeset.old_relations
                           .order(:relation_id, :version)
                           .offset(ELEMENTS_PER_PAGE * (@current_relation_page - 1))
                           .limit(ELEMENTS_PER_PAGE)
  end

  helper_method def element_pages_count(elements_count)
    [1, 1 + ((elements_count - 1) / ELEMENTS_PER_PAGE)].max
  end

  helper_method def element_range_values(elements_count, page)
    { :x => (ELEMENTS_PER_PAGE * (page - 1)) + 1,
      :y => [ELEMENTS_PER_PAGE * page, elements_count].min,
      :count => elements_count }
  end
end
