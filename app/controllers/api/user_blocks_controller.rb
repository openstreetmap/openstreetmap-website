module Api
  class UserBlocksController < ApiController
    before_action :check_api_readable

    authorize_resource

    around_action :api_call_handle_error, :api_call_timeout
    before_action :set_request_formats

    def show
      raise OSM::APIBadUserInput, "No id was given" unless params[:id]

      @user_block = UserBlock.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise OSM::APINotFoundError
    end
  end
end
