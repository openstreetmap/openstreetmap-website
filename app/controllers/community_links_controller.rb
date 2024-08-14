class CommunityLinksController < ApplicationController
  layout "site"
  before_action :authorize_web

  before_action :set_link, :only => [:destroy, :edit, :update]

  load_and_authorize_resource :except => [:create, :new]
  authorize_resource

  def index
    @community = Community.friendly.find(params[:community_id])
    @links = @community.community_links
  end

  def new
    return "missing parameter community_id" unless params.key?(:community_id)

    @community = Community.friendly.find(params[:community_id])
    @title = t ".title"
    @link = CommunityLink.new
    @link.community_id = params[:community_id]
  end

  def edit; end

  def create
    @community = Community.friendly.find(params[:community_id])
    @link = @community.community_links.build(link_params)
    if @link.save
      response.set_header("link_id", @link.id) # for testing
      redirect_to @link.community, :notice => t(".success")
    else
      render "new"
    end
  end

  def update
    if @link.update(link_params)
      redirect_to @link.community, :notice => t(".success")
    else
      flash.now[:alert] = t(".failure")
      render :edit
    end
  end

  def destroy
    community_id = @link.community_id
    @link.delete
    redirect_to community_path(community_id)
  end

  private

  def set_link
    @link = CommunityLink.find(params[:id])
  end

  def link_params
    params.require(:community_link).permit(:community_id, :text, :url)
  end
end
