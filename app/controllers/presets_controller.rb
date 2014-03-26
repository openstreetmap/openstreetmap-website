class PresetsController < ApplicationController

  layout false
  before_filter :check_api_readable
  before_filter :check_api_writable
  before_filter :setup_user_auth
  before_filter :authorize
  before_filter :set_locale
  around_filter :api_call_handle_error, :api_call_timeout
  after_filter :compress_output
  before_action :set_preset, only: [:show, :edit, :update, :destroy]

  # GET /presets
  def index
    @presets = Preset.all

    respond_to do |format|
      format.json { render :action => :index }
#      format.xml { render :action => :show }
    end
  end

  # GET /presets/1
  def show
  end

  # GET /presets/new
  #def new
  #  @preset = Preset.new
  #end

  # GET /presets/1/edit
  #def edit
  #end

  # POST /presets
  def create
    raise OSM::APIBadUserInput.new("No json was given") unless params[:json]
    @preset = Preset.new(preset_params)

    @preset.save!

    respond_to do |format|
      format.json { render :action => :show }
#      format.xml { render :action => :show }
    end
  end

  # PATCH/PUT /presets/1
  def update
    if @preset.update(preset_params)
      render action: 'show'
    end
  end

  # DELETE /presets/1
  def destroy
    @preset.destroy
    #render action: 'index'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_preset
      @preset = Preset.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def preset_params
      params.permit(:json)
    end
end
