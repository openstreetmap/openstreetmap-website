class CommunitiesController < ApplicationController
  include UserMethods

  layout "site"
  before_action :authorize_web

  before_action :set_community, :only => [:edit, :show, :step_up, :update]

  helper_method :recent_changesets

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def index
    @critical_mass = 3
    display_name = params[:user_display_name]
    if display_name
      @user = User.active.find_by(:display_name => display_name)
      if @user
        @title = t ".title", :display_name => @user.display_name
        @communities_leading = @user.communities_lead
      else
        render_unknown_user display_name
        return
      end
    elsif current_user
      @title = t ".title", :display_name => current_user.display_name
      @communities_leading = current_user.communities_lead
    end

    # Only list out communities that have at least n members in order to mitigate spam.  In order to get
    # a community listed, the organizer must find n members and give them the link to the page manually.
    @all_communities = Community
                       .joins(:community_members)
                       .group("communities.id")
                       .having("COUNT(communities.id) >= #{@critical_mass}")

    @my_communities = current_user ? current_user.communities : []
  end

  # GET /communities/mycity
  # GET /communities/mycity.json
  def show
    # for existing or new member
    @current_user_membership = CommunityMember.find_or_initialize_by(
      :community => @community, :user_id => current_user&.id
    )
  end

  def new
    @title = t ".title"
    @community = Community.new
  end

  def edit; end

  def create
    @community = Community.new(community_params)
    @community.leader = current_user
    if @community.save && add_first_organizer
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

  def step_up
    message = nil
    if @community.organizers.empty?
      if @community.member?(current_user)
        message = t ".you_have_stepped_up"
        add_first_organizer
      else
        message = t ".only_members_can_step_up"
      end
    else
      message = t ".already_has_organizer"
    end
    redirect_to @community, :notice => message
  end

  private

  def add_first_organizer
    membership = CommunityMember.new(
      {
        :community_id => @community.id,
        :user_id => current_user.id,
        :role => CommunityMember::Roles::ORGANIZER
      }
    )
    membership.save
  end

  def recent_changesets
    bbox = @community.bbox.to_scaled
    Changeset
      .where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
             bbox.max_lon.to_i, bbox.min_lon.to_i, bbox.max_lat.to_i, bbox.min_lat.to_i)
      .order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)
  end

  def set_community
    @community = Community.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @not_found_community = params[:id]
    render "no_such_community", :status => :not_found
  end

  def community_params
    params.require(:community).permit(
      :name, :location, :latitude, :longitude,
      :min_lat, :max_lat, :min_lon, :max_lon,
      :description
    )
  end
end
