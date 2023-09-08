class UserMutesController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale

  authorize_resource

  before_action :lookup_user, :only => [:create, :destroy]
  before_action :check_database_readable
  before_action :check_database_writable, :only => [:create, :destroy]

  def index
    # @params = params.permit
    # @user_blocks_pages, @user_blocks = paginate(:user_blocks,
    #                                             :include => [:user, :creator, :revoker],
    #                                             :order => "user_blocks.ends_at DESC",
    #                                             :per_page => 20)
  end

  def create
    user_mute = UserMute.new(
      :creator => current_user,
      :appointee => @user,
    )

    if user_mute.save
      flash[:notice] = t(".notice", :name => user_mute.appointee.display_name)
    else
      flash[:error] = t(".error")
    end

    redirect_back fallback_location: user_mutes_path(current_user)
  end

  def destroy
    user_mute = UserMute.find_by(creator: current_user, appointee: @user)

    if user_mute.destroy
      flash[:notice] = t(".notice", :name => user_mute.appointee.display_name)
    else
      flash[:error] = t(".error")
    end

    redirect_back fallback_location: user_mutes_path(current_user)
  end

end
