class MicrocosmsController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_microcosm, :only => [:edit, :show, :update]

  authorize_resource

  def index
    @microcosms = Microcosm.order(:name)
  end

  # GET /microcosms/mycity
  # GET /microcosms/mycity.json
  def show; end

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
    @microcosm = Microcosm.new
  end

  def create
    @microcosm = Microcosm.new(microcosm_params)
    if @microcosm.save
      redirect_to @microcosm, :notice => t(".success")
    else
      render "new"
    end
  end

  private

  def set_microcosm
    @microcosm = Microcosm.friendly.find(params[:id])
  end

  def microcosm_params
    params.require(:microcosm).permit(
      :name, :location, :lat, :lon,
      :min_lat, :max_lat, :min_lon, :max_lon,
      :description
    )
  end
end
