module Api
  class CapabilitiesController < ApiController
    authorize_resource :class => false

    around_action :api_call_handle_error, :api_call_timeout

    # External apps that use the api are able to query the api to find out some
    # parameters of the API.
    def show
      @database_status = database_status
      @api_status = api_status
      @gpx_status = gpx_status
    end
  end
end
