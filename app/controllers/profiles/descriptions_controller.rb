module Profiles
  class DescriptionsController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale

    authorize_resource :class => :profile

    before_action :check_database_readable
    before_action :check_database_writable, :only => [:update]

    def show; end

    def update
      social_links_params = params.permit(:user => [:social_links_attributes => [:id, :url, :_destroy]])
      current_user.assign_attributes(social_links_params[:user])

      if params[:user][:description] != current_user.description
        current_user.description = params[:user][:description]
        current_user.description_format = "markdown"
      end

      case params[:avatar_action]
      when "new"
        current_user.avatar.attach(params[:user][:avatar])
        current_user.image_use_gravatar = false
      when "delete"
        current_user.avatar.purge_later
        current_user.image_use_gravatar = false
      when "gravatar"
        current_user.avatar.purge_later
        current_user.image_use_gravatar = true
      end

      current_user.company = params[:user][:company]

      current_user.home_lat = params[:user][:home_lat]
      current_user.home_lon = params[:user][:home_lon]
      current_user.home_location_name = params[:user][:home_location_name]

      if current_user.save
        flash[:notice] = t ".success"
        redirect_to user_path(current_user)
      else
        flash.now[:error] = t ".failure"
        render :show
      end
    end
  end
end
