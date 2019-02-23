module Api
  class CapabilitiesController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :api_deny_access_handler

    authorize_resource :class => false

    around_action :api_call_handle_error, :api_call_timeout

    # External apps that use the api are able to query the api to find out some
    # parameters of the API. It currently returns:
    # * minimum and maximum API versions that can be used.
    # * maximum area that can be requested in a bbox request in square degrees
    # * number of tracepoints that are returned in each tracepoints page
    def show
      @database_status = database_status
      @api_status = api_status
      @gpx_status = gpx_status
    end
  end
end
