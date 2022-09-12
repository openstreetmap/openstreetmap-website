class ProfilesController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource :class => false

  before_action :check_database_readable
  before_action :check_database_writable, :only => [:update]

  def edit; end

  def update
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

    current_user.home_lat = params[:user][:home_lat]
    current_user.home_lon = params[:user][:home_lon]

    if current_user.save
      flash[:notice] = t ".success"
      redirect_to user_path(current_user)
    else
      flash.now[:error] = t ".failure"
      render :edit
    end
  end
end
