class MicrocosmsController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_microcosm, :only => [:show]

  authorize_resource

  def index
    @microcosms = Microcosm.order(:name)
  end

  # GET /microcosms/mycity
  # GET /microcosms/mycity.json
  def show; end

  def edit; end

  private

  def set_microcosm
    @microcosm = Microcosm.friendly.find(params[:id])
  end
end
