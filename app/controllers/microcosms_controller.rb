class MicrocosmsController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_microcosm, :only => [:edit, :show, :update]

  helper_method :recent_changesets

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def index
    # Using Arel.sql here because we're using known-safe values.
    @microcosms = Microcosm.order(Arel.sql(sunniest_communities))

    @microcosms_organized = current_user ? current_user.microcosms_organized : []
  end

  def of_user
    display_name = params[:display_name]
    @user = User.active.where(:display_name => display_name).first
    if @user.nil?
      render_unknown_user display_name
      return
    end

    @microcosms_organized = @user.microcosms_organized
    @title = t ".title", :display_name => @user.display_name
    render :of_user
  end

  # GET /microcosms/mycity
  # GET /microcosms/mycity.json
  def show; end

  def edit; end

  def update
    if @microcosm.update(microcosm_params)
      redirect_to @microcosm, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def new
    @title = t "microcosms.new.title"
    @microcosm = Microcosm.new
  end

  def create
    @microcosm = Microcosm.new(microcosm_params)
    @microcosm.organizer = current_user
    if @microcosm.save
      redirect_to @microcosm, :notice => t(".success")
    else
      render "new"
    end
  end

  def recent_changesets
    bbox = BoundingBox.new(@microcosm.min_lon, @microcosm.min_lat, @microcosm.max_lon, @microcosm.max_lat).to_scaled
    Changeset
      .where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
             bbox.max_lon.to_i, bbox.min_lon.to_i, bbox.max_lat.to_i, bbox.min_lat.to_i)
      .order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)
  end

  private

  ##
  # Build an ORDER BY clause that sorts microcosms such that the ones
  # getting the most sunlight are ranked highest.  These are the groups
  # where people are awake and mapping.
  #
  # We ignore timezone and daylight saving here.  Only longitude matters.
  def sunniest_communities
    brightest_minute_of_day = "(60 * 12)" # noon
    # convert float to numeric because extract returns floats
    minute_of_day = "(60 * EXTRACT(HOUR FROM current_timestamp) + EXTRACT(MINUTE FROM current_timestamp))::numeric"
    # longitude facing the sun
    lfts = "((#{brightest_minute_of_day} - #{minute_of_day}) / 4)"
    # find shortest span between lfts and the microcosm longitude
    # pg doesn't have mod for floats, so convert to numeric
    clockwise_delta = "((#{lfts} - longitude::numeric + 360) % 360)"
    anticlockwise_delta = "((longitude::numeric - #{lfts} + 360) % 360)"
    "least(#{clockwise_delta}, #{anticlockwise_delta})"
  end

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
    longitude = ((longitude + 180) % 360) - 180
    microcosm_params[:longitude] = longitude.to_s
  end
end
