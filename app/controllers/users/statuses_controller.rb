module Users
  class StatusesController < ApplicationController
    layout "site"

    before_action :authorize_web
    before_action :set_locale
    before_action :check_database_readable

    authorize_resource :class => :user_status

    before_action :lookup_user_by_name

    ##
    # sets a user's status
    def update
      @user.activate! if params[:event] == "activate"
      @user.confirm! if params[:event] == "confirm"
      @user.unconfirm! if params[:event] == "unconfirm"
      @user.hide! if params[:event] == "hide"
      @user.unhide! if params[:event] == "unhide"
      @user.unsuspend! if params[:event] == "unsuspend"
      @user.soft_destroy! if params[:event] == "soft_destroy" # destroy a user, marking them as deleted and removing personal data
      redirect_to user_path(params[:user_display_name])
    end

    private

    ##
    # ensure that there is a "user" instance variable
    def lookup_user_by_name
      @user = User.find_by!(:display_name => params[:user_display_name])
    rescue ActiveRecord::RecordNotFound
      redirect_to user_path(params[:user_display_name]) unless @user
    end
  end
end
