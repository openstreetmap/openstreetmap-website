class FollowsController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable
  before_action :lookup_user

  def show
    @already_follows = current_user.follows?(@user)
  end

  def create
    follow = Follow.new
    follow.follower = current_user
    follow.following = @user
    if current_user.follows?(@user)
      flash[:warning] = t ".already_followed", :name => @user.display_name
    elsif current_user.follows.where(:created_at => Time.now.utc - 1.hour..).count >= current_user.max_follows_per_hour
      flash[:error] = t ".limit_exceeded"
    elsif follow.save
      flash[:notice] = t ".success", :name => @user.display_name
      UserMailer.follow_notification(follow).deliver_later
    else
      follow.add_error(t(".failed", :name => @user.display_name))
    end

    referer = safe_referer(params[:referer]) if params[:referer]

    redirect_to referer || user_path
  end

  def destroy
    if current_user.follows?(@user)
      Follow.where(:follower => current_user, :following => @user).delete_all
      flash[:notice] = t ".success", :name => @user.display_name
    else
      flash[:error] = t ".not_followed", :name => @user.display_name
    end

    referer = safe_referer(params[:referer]) if params[:referer]

    redirect_to referer || user_path
  end
end
