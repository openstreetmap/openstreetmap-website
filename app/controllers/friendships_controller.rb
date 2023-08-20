class FriendshipsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable, :only => [:make_friend, :remove_friend]
  before_action :lookup_friend, :only => [:make_friend, :remove_friend]

  def make_friend
    if request.post?
      friendship = Friendship.new
      friendship.befriender = current_user
      friendship.befriendee = @friend
      if current_user.friends_with?(@friend)
        flash[:warning] = t ".already_a_friend", :name => @friend.display_name
      elsif current_user.friendships.where("created_at >= ?", Time.now.utc - 1.hour).count >= current_user.max_friends_per_hour
        flash.now[:error] = t ".limit_exceeded"
      elsif friendship.save
        flash[:notice] = t ".success", :name => @friend.display_name
        UserMailer.friendship_notification(friendship).deliver_later
      else
        friendship.add_error(t(".failed", :name => @friend.display_name))
      end

      referer = safe_referer(params[:referer]) if params[:referer]

      redirect_to referer || user_path
    end
  end

  def remove_friend
    if request.post?
      if current_user.friends_with?(@friend)
        Friendship.where(:befriender => current_user, :befriendee => @friend).delete_all
        flash[:notice] = t ".success", :name => @friend.display_name
      else
        flash[:error] = t ".not_a_friend", :name => @friend.display_name
      end

      referer = safe_referer(params[:referer]) if params[:referer]

      redirect_to referer || user_path
    end
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
