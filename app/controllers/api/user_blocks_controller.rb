module Api
  class UserBlocksController < ApiController
    authorize_resource

    before_action :set_request_formats

    def show
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      @user_block = UserBlock.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise OSM::APINotFoundError
    end
  end
end
