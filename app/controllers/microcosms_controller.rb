class MicrocosmsController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_microcosm, :only => [:edit, :show, :show_events, :show_members, :update]

  helper_method :recent_changesets

  authorize_resource

  def index
    @microcosms = Microcosm.order(:longitude)
  end

  # GET /microcosms/mycity
  # GET /microcosms/mycity.json
  def show; end

  def show_members; end

  def show_events; end

  def edit; end

  def update
    respond_to do |format|
      if @microcosm.update(microcosm_params)
        format.html { redirect_to @microcosm, :notice => t(".success") }
      else
        format.html { render :edit }
      end
    end
  end

  def new
    @microcosm = Microcosm.new
  end

  def create
    @microcosm = Microcosm.new(microcosm_params)
    if @microcosm.save
      redirect_to microcosms_path, :notice => t(".success")
    else
      redirect_to microcosms_path, :notice => t(".failure")
    end
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

  private

  def set_microcosm
    @microcosm = Microcosm.friendly.find(params[:id])
  end

  def microcosm_params
    params.require(:microcosm).permit(
      :name, :location, :latitude, :longitude,
      :min_lat, :max_lat, :min_lon, :max_lon,
      :description
    )
  end
end
