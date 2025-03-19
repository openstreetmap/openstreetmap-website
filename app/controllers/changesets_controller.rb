# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetsController < ApplicationController
  include UserMethods
  include PaginationMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }
  before_action :require_oauth, :only => :show

  authorize_resource

  around_action :web_timeout

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
        changesets = conditions_bbox(changesets, BoundingBox.from_bbox_params(params))
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
      @node_pages, @nodes = paginate(:old_nodes, :conditions => { :changeset_id => @changeset.id }, :order => [:node_id, :version], :per_page => 20, :parameter => "node_page")
      render :partial => "elements", :locals => { :type => "node", :elements => @nodes, :pages => @node_pages }
    when "changeset_ways"
      @way_pages, @ways = paginate(:old_ways, :conditions => { :changeset_id => @changeset.id }, :order => [:way_id, :version], :per_page => 20, :parameter => "way_page")
      render :partial => "elements", :locals => { :type => "way", :elements => @ways, :pages => @way_pages }
    when "changeset_relations"
      @relation_pages, @relations = paginate(:old_relations, :conditions => { :changeset_id => @changeset.id }, :order => [:relation_id, :version], :per_page => 20, :parameter => "relation_page")
      render :partial => "elements", :locals => { :type => "relation", :elements => @relations, :pages => @relation_pages }
    else
      @comments = if current_user&.moderator?
                    @changeset.comments.unscope(:where => :visible).includes(:author)
                  else
                    @changeset.comments.includes(:author)
                  end
      @node_pages, @nodes = paginate(:old_nodes, :conditions => { :changeset_id => @changeset.id }, :order => [:node_id, :version], :per_page => 20, :parameter => "node_page")
      @way_pages, @ways = paginate(:old_ways, :conditions => { :changeset_id => @changeset.id }, :order => [:way_id, :version], :per_page => 20, :parameter => "way_page")
      @relation_pages, @relations = paginate(:old_relations, :conditions => { :changeset_id => @changeset.id }, :order => [:relation_id, :version], :per_page => 20, :parameter => "relation_page")
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
  # if a bounding box was specified do some sanity checks.
  # restrict changesets to those enclosed by a bounding box
  def conditions_bbox(changesets, bbox)
    if bbox
      bbox.check_boundaries
      bbox = bbox.to_scaled

      changesets.where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
                       bbox.max_lon.to_i, bbox.min_lon.to_i,
                       bbox.max_lat.to_i, bbox.min_lat.to_i)
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
