module Api
  class UsersController < ApiController
    layout "site", :except => [:api_details]

    before_action :disable_terms_redirect, :only => [:api_details]
    before_action :authorize, :only => [:api_details, :api_gpx_files]
    before_action :api_deny_access_handler

    authorize_resource

    before_action :check_api_readable
    around_action :api_call_handle_error
    before_action :lookup_user_by_id, :only => [:api_read]

    def api_read
      if @user.visible?
        render :action => :api_read, :content_type => "text/xml"
      else
        head :gone
      end
    end

    def api_details
      @user = current_user
      render :action => :api_read, :content_type => "text/xml"
    end

    def api_users
      raise OSM::APIBadUserInput, "The parameter users is required, and must be of the form users=id[,id[,id...]]" unless params["users"]

      ids = params["users"].split(",").collect(&:to_i)

      raise OSM::APIBadUserInput, "No users were given to search for" if ids.empty?

      @users = User.visible.find(ids)

      render :action => :api_users, :content_type => "text/xml"
    end

    def api_gpx_files
      doc = OSM::API.new.get_xml_doc
      current_user.traces.reload.each do |trace|
        doc.root << trace.to_xml_node
      end
      render :xml => doc.to_s
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
