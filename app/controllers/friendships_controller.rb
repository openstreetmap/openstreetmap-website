class FriendshipsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :check_database_writable, :only => [:make_friend, :remove_friend]

  def make_friend
    @new_friend = User.find_by(:display_name => params[:display_name])

    if @new_friend
      if request.post?
        friendship = Friendship.new
        friendship.befriender = current_user
        friendship.befriendee = @new_friend
        if current_user.friends_with?(@new_friend)
          flash[:warning] = t "friendships.make_friend.already_a_friend", :name => @new_friend.display_name
        elsif current_user.friendships.where("created_at >= ?", Time.now.utc - 1.hour).count >= current_user.max_friends_per_hour
          flash.now[:error] = t "friendships.make_friend.limit_exceeded"
        elsif friendship.save
          flash[:notice] = t "friendships.make_friend.success", :name => @new_friend.display_name
          UserMailer.friendship_notification(friendship).deliver_later
        else
          friendship.add_error(t("friendships.make_friend.failed", :name => @new_friend.display_name))
        end

        referer = safe_referer(params[:referer]) if params[:referer]

        redirect_to referer || user_path
      end
    else
      render_unknown_user params[:display_name]
    end
  end

  def remove_friend
    @friend = User.find_by(:display_name => params[:display_name])

    if @friend
      if request.post?
        if current_user.friends_with?(@friend)
          Friendship.where(:befriender => current_user, :befriendee => @friend).delete_all
          flash[:notice] = t "friendships.remove_friend.success", :name => @friend.display_name
        else
          flash[:error] = t "friendships.remove_friend.not_a_friend", :name => @friend.display_name
        end

        referer = safe_referer(params[:referer]) if params[:referer]

        redirect_to referer || user_path
      end
    else
      render_unknown_user params[:display_name]
    end
  end
end
