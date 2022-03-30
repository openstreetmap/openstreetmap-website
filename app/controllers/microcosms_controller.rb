class MicrocosmsController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_microcosm, :only => [:edit, :show, :show_events, :show_members, :step_up, :update]

  helper_method :recent_changesets

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def index
    # TODO: OMG is the math right here?
    minute_of_day = "(60 * EXTRACT(HOUR FROM current_timestamp) + EXTRACT(MINUTE FROM current_timestamp))"
    morning = "(60 * 6)" # 6 AM
    long_facing_sun = "(#{minute_of_day} + #{morning}) / 4"
    # Using Arel.sql here due to warning about non-attributes arguments will be disallowed in Rails 6.1.
    # Only list out microcosms that have at least 2 members in order to mitigate spam.  In order to get
    # a microcosm listed, the organizer must find 2 members and give them the link to the page manually.
    @microcosms = Microcosm
                  .joins(:microcosm_members)
                  .group("microcosms.id")
                  .having("COUNT(microcosms.id) >= #{Settings.microcosm_critical_mass}")
                  .order(Arel.sql("longitude + 180 + #{long_facing_sun} DESC"))

    @my_microcosms = current_user ? current_user.microcosms : []
    @not_my_microcosms = @microcosms - @my_microcosms
  end

  # GET /microcosms/mycity
  # GET /microcosms/mycity.json
  def show
    @my_membership = MicrocosmMember.find_or_initialize_by(:microcosm_id => @microcosm.id, :user_id => current_user&.id)
  end

  def show_members
    # Could use pluralize, but we don't need that at this time.
    @roles = MicrocosmMember::Roles::ALL_ROLES.map { |r| "#{r}s" }
  end

  def show_events; end

  def edit; end

  def update
    if @microcosm.update(microcosm_params)
      redirect_to @microcosm, :notice => t(".success")
    else
      flash[:alert] = t(".failure")
      render :edit
    end
  end

  def new
    @title = t "microcosms.new.title"
    @microcosm = Microcosm.new
  end

  def create
    @microcosm = Microcosm.new(microcosm_params)
    if @microcosm.save && add_first_organizer
      redirect_to @microcosm, :notice => t(".success")
    else
      flash[:alert] = t(".failure")
      render "new"
    end
  end

  def add_first_organizer
    membership = MicrocosmMember.new(
      {
        :microcosm_id => @microcosm.id,
        :user_id => current_user.id,
        :role => MicrocosmMember::Roles::ORGANIZER
      }
    )
    membership.save
  end

  def recent_changesets
    bbox = BoundingBox.new(@microcosm.min_lon, @microcosm.min_lat, @microcosm.max_lon, @microcosm.max_lat).to_scaled
    Changeset
      .where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
             bbox.max_lon.to_i,
             bbox.min_lon.to_i,
             bbox.max_lat.to_i,
             bbox.min_lat.to_i)
      .order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)
  end

  def step_up
    message = nil
    if @microcosm.organizers.empty?
      if @microcosm.member?(current_user)
        message = t ".you_have_stepped_up"
        add_first_organizer
      else
        message = t ".only_members_can_step_up"
      end
    else
      message = t ".already_has_organizer"
    end
    # render :show
    redirect_to @microcosm, :notice => message
  end

  private

  def set_microcosm
    @microcosm = Microcosm.friendly.find(params[:id])
  end

  def microcosm_params
    normalize_longitude(params[:microcosm])
    params.require(:microcosm).permit(
      :name, :location, :latitude, :longitude,
      :min_lat, :max_lat, :min_lon, :max_lon,
      :description
    )
  end

  def normalize_longitude(microcosm_params)
    longitude = microcosm_params[:longitude].to_f
    longitude = (longitude + 180) % 360 - 180
    microcosm_params[:longitude] = longitude.to_s
  end
end
