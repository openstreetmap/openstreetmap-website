module Administrator
  class UsersController < ApplicationController
    include PaginationMethods

    layout "site"

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource

    ##
    # display a list of users matching specified criteria
    def index
      if request.post?
        ids = params[:user].keys.collect(&:to_i)

        User.where(:id => ids).update_all(:status => "confirmed") if params[:confirm]
        User.where(:id => ids).update_all(:status => "deleted") if params[:hide]

        redirect_to url_for(:status => params[:status], :ip => params[:ip], :page => params[:page])
      else
        @params = params.permit(:status, :ip, :before, :after)

        users = User.all
        users = users.where(:status => @params[:status]) if @params[:status]
        users = users.where(:creation_ip => @params[:ip]) if @params[:ip]

        @users_count = users.count
        @users, @newer_users_id, @older_users_id = get_page_items(users, :limit => 50)

        render :partial => "page" if turbo_frame_request_id == "pagination"
      end
    end
  end
end
