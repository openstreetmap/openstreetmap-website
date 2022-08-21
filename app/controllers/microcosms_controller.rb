class MicrocosmsController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_microcosm, :only => [:edit, :show, :update]

  helper_method :recent_changesets

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def index
    @microcosms = Microcosm.order(:longitude)
  end

  # GET /microcosms/mycity
  # GET /microcosms/mycity.json
  def show; end

  def new
    @title = t ".title"
    @microcosm = Microcosm.new
  end

  def edit; end

  def create
    @microcosm = Microcosm.new(microcosm_params)
    @microcosm.organizer = current_user
    if @microcosm.save
      redirect_to @microcosm, :notice => t(".success")
    else
      render "new"
    end
  end

  def update
    if @microcosm.update(microcosm_params)
      redirect_to @microcosm, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  private

  def recent_changesets
    bbox = @microcosm.bbox.to_scaled
    Changeset
      .where("min_lon < ? and max_lon > ? and min_lat < ? and max_lat > ?",
             bbox.max_lon.to_i, bbox.min_lon.to_i, bbox.max_lat.to_i, bbox.min_lat.to_i)
      .order("changesets.id DESC").limit(20).preload(:user, :changeset_tags, :comments)
  end

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
