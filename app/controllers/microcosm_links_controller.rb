class MicrocosmLinksController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_link, :only => [:destroy, :edit, :update]

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def edit; end

  def update
    if @link.update(link_params)
      redirect_to @link.microcosm, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def new
    return "missing parameter microcosm_id" unless params.key?(:microcosm_id)

    @title = t "microcosm_links.new.title"
    @link = MicrocosmLink.new
    @link.microcosm_id = params[:microcosm_id]
  end

  def index
    return "missing parameter microcosm_id" unless params.key?(:microcosm_id)

    @microcosm_id = params[:microcosm_id]
    @links = MicrocosmLink.where(:microcosm_id => @microcosm_id)
  end

  def create
    @link = MicrocosmLink.new(link_params)
    if @link.save
      response.set_header("link_id", @link.id) # for testing
      redirect_to @link.microcosm, :notice => t(".success")
    else
      render "new"
    end
  end

  def destroy
    microcosm_id = @link.microcosm_id
    @link.delete
    redirect_to microcosm_path(microcosm_id)
  end

  private

  def set_link
    @link = MicrocosmLink.find(params[:id])
  end

  def link_params
    params.require(:microcosm_link).permit(:microcosm_id, :site, :url)
  end
end
