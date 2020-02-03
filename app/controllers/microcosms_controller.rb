class MicrocosmsController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_microcosm, :only => [:edit, :show, :show_events, :show_members, :update]

  authorize_resource

  def index
    @microcosms = Microcosm.order(:name)
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

  private

  def set_microcosm
    @microcosm = Microcosm.friendly.find(params[:id])
  end

  def microcosm_params
    mic_params = params.require(:microcosm).permit(
      :name, :location, :lat, :lon,
      :min_lat, :max_lat, :min_lon, :max_lon,
      :description
    )
    mic_params[:lat] = Float(params[:microcosm][:lat])  # TODO: Handle exception.
    mic_params[:lon] = Float(params[:microcosm][:lon])
    mic_params
  end
end
