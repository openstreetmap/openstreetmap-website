class FollowsController < ApplicationController
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable
  before_action :lookup_friend

  def show
    @already_follows = current_user.friends_with?(@friend)
  end

  def create
    follow = Follow.new
    follow.follower = current_user
    follow.following = @friend
    if current_user.friends_with?(@friend)
      flash[:warning] = t ".already_followed", :name => @friend.display_name
    elsif current_user.follows.where(:created_at => Time.now.utc - 1.hour..).count >= current_user.max_friends_per_hour
      flash[:error] = t ".limit_exceeded"
    elsif follow.save
      flash[:notice] = t ".success", :name => @friend.display_name
      UserMailer.friendship_notification(follow).deliver_later
    else
      follow.add_error(t(".failed", :name => @friend.display_name))
    end

    referer = safe_referer(params[:referer]) if params[:referer]

    redirect_to referer || user_path
  end

  def destroy
    if current_user.friends_with?(@friend)
      Follow.where(:follower => current_user, :following => @friend).delete_all
      flash[:notice] = t ".success", :name => @friend.display_name
    else
      flash[:error] = t ".not_followed", :name => @friend.display_name
    end

    referer = safe_referer(params[:referer]) if params[:referer]

    redirect_to referer || user_path
  end

  private

  ##
  # ensure that there is a "friend" instance variable
  def lookup_friend
    @friend = User.active.find_by!(:display_name => params[:display_name])
  rescue ActiveRecord::RecordNotFound
    render_unknown_user params[:display_name]
  end
end
