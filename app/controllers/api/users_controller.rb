module Api
  class UsersController < ApiController
    before_action :check_api_readable
    before_action :disable_terms_redirect, :only => [:details]
    before_action :setup_user_auth, :only => [:show, :index]
    before_action :authorize, :only => [:details, :gpx_files]

    authorize_resource

    around_action :api_call_handle_error
    before_action :lookup_user_by_id, :only => [:show]

    before_action :set_request_formats, :except => [:gpx_files]

    def show
      if @user.visible?
        # Render the result
        respond_to do |format|
          format.xml
          format.json
        end
      else
        head :gone
      end
    end

    def details
      @user = current_user
      # Render the result
      respond_to do |format|
        format.xml { render :show }
        format.json { render :show }
      end
    end

    def index
      raise OSM::APIBadUserInput, "The parameter users is required, and must be of the form users=id[,id[,id...]]" unless params["users"]

      ids = params["users"].split(",").collect(&:to_i)

      raise OSM::APIBadUserInput, "No users were given to search for" if ids.empty?

      @users = User.visible.find(ids)

      # Render the result
      respond_to do |format|
        format.xml
        format.json
      end
    end

    def gpx_files
      @traces = current_user.traces.reload
      render :content_type => "application/xml"
    end

    private

    ##
    # ensure that there is a "user" instance variable
    def lookup_user_by_id
      @user = User.find(params[:id])
    end

    ##
    #
    def disable_terms_redirect
      # this is necessary otherwise going to the user terms page, when
      # having not agreed already would cause an infinite redirect loop.
      # it's .now so that this doesn't propagate to other pages.
      flash.now[:skip_terms] = true
    end
  end
end
