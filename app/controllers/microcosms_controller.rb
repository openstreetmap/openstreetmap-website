class MicrocosmsController < ApplicationController
  layout "site"
  # before_action :authorize_web

  before_action :set_microcosm, :only => [:show]
  before_action :set_microcosm_by_key, :only => [:show_by_key]

  authorize_resource

  def show; end

  # GET /microcosms/mycity
  # GET /microcosms/mycity.json
  def show_by_key
    render :action => "show"
  end

  private

  def set_microcosm
    @microcosm = Microcosm.find(params[:id])
  end

  def set_microcosm_by_key
    @microcosm = Microcosm.find_by(:key => params[:key])
  end
end
