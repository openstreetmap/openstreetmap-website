class CommunitiesController < ApplicationController
  include UserMethods

  layout "site"
  before_action :authorize_web

  before_action :set_community, :only => [:edit, :show, :update]

  helper_method :recent_changesets

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def index
    display_name = params[:user_display_name]
    if display_name
      @user = User.active.find_by(:display_name => display_name)
      if @user
        @title = t ".title", :display_name => @user.display_name
        @communities_organized = @user.communities_organized
      else
        render_unknown_user display_name
        return
      end
    elsif current_user
      @title = t ".title", :display_name => current_user.display_name
      @communities_organized = current_user.communities_organized
    end

    @all_communities = Community.order(:name)
  end

  # GET /communities/mycity
  # GET /communities/mycity.json
  def show; end

  def new
    @title = t ".title"
    @community = Community.new
  end

  def edit; end

  def create
    @community = Community.new(community_params)
    @community.organizer = current_user
    if @community.save
      redirect_to @community, :notice => t(".success")
    else
      render "new"
    end
  end

  def update
    if @community.update(community_params)
      redirect_to @community, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  private

  def recent_changesets
    bbox = @community.bbox.to_scaled
    Changeset
      .where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
             bbox.max_lon.to_i, bbox.min_lon.to_i, bbox.max_lat.to_i, bbox.min_lat.to_i)
      .order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)
  end

  def set_community
    @community = Community.friendly.find(params[:id])
  end

  def community_params
    params.require(:community).permit(
      :name, :location, :latitude, :longitude,
      :min_lat, :max_lat, :min_lon, :max_lon,
      :description
    )
  end
end
