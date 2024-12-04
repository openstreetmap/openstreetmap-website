# The ChangesetController is the RESTful interface to Changeset objects

class ChangesetsController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action -> { check_database_readable(:need_api => true) }, :only => [:index, :feed, :show]
  before_action :require_oauth, :only => :show
  before_action :check_database_writable, :only => [:subscribe, :unsubscribe]

  authorize_resource

  around_action :web_timeout

  ##
  # list non-empty changesets in reverse chronological order
  def index
    param! :max_id, Integer, :min => 1

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
                       changesets.where(:user => user)
                     else
                       changesets.where("false")
                     end
      elsif @params[:bbox]
        changesets = conditions_bbox(changesets, BoundingBox.from_bbox_params(params))
      elsif @params[:friends] && current_user
        changesets = changesets.where(:user => current_user.friends.identifiable)
      elsif @params[:nearby] && current_user
        changesets = changesets.where(:user => current_user.nearby)
      end

      changesets = changesets.where(:changesets => { :id => ..@params[:max_id] }) if @params[:max_id]

      @changesets = changesets.order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)

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

      render :partial => "elements", :locals => { :type => "node", :paginator => @nodes_paginator }
    when "changeset_ways"
      load_ways

      render :partial => "elements", :locals => { :type => "way", :paginator => @ways_paginator }
    when "changeset_relations"
      load_relations

      render :partial => "elements", :locals => { :type => "relation", :paginator => @relations_paginator }
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

  ##
  # subscribe to a changeset
  def subscribe
    @changeset = Changeset.find(params[:id])

    if request.post?
      @changeset.subscribe(current_user) unless @changeset.subscribed?(current_user)

      redirect_to changeset_path(@changeset)
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
  end

  ##
  # unsubscribe from a changeset
  def unsubscribe
    @changeset = Changeset.find(params[:id])

    if request.post?
      @changeset.unsubscribe(current_user)

      redirect_to changeset_path(@changeset)
    end
  rescue ActiveRecord::RecordNotFound
    render :action => "no_such_entry", :status => :not_found
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

  def load_nodes
    nodes = OldNode.where(:changeset => @changeset).order(:node_id, :version)
    @nodes_paginator = ElementsPaginator.new(nodes, 20, params[:node_page])
  end

  def load_ways
    ways = OldWay.where(:changeset => @changeset).order(:way_id, :version)
    @ways_paginator = ElementsPaginator.new(ways, 20, params[:way_page])
  end

  def load_relations
    relations = OldRelation.where(:changeset => @changeset).order(:relation_id, :version)
    @relations_paginator = ElementsPaginator.new(relations, 20, params[:relation_page])
  end

  class ElementsPaginator
    attr_reader :elements_count, :elements_per_page, :current_page, :current_page_elements

    def initialize(elements, elements_per_page, current_page = 1)
      @elements_count = elements.count
      @elements_per_page = elements_per_page.to_i
      @current_page = current_page.to_i.clamp(1, pages_count)
      @current_page_elements = elements.offset(@elements_per_page * (@current_page - 1)).limit(@elements_per_page)
    end

    def pages_count
      [1, 1 + ((elements_count - 1) / elements_per_page)].max
    end

    def pages
      1..pages_count
    end

    def pages_window(window_size, page = current_page)
      [page - window_size, pages.first].max..[page + window_size, pages.last].min
    end

    def lower_element_number(page = current_page)
      (elements_per_page * (page - 1)) + 1
    end

    def upper_element_number(page = current_page)
      [elements_per_page * page, elements_count].min
    end
  end
end
