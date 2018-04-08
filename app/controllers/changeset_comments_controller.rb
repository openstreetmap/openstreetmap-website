class ChangesetCommentsController < ApplicationController
  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :require_user, :only => :subscribed
  before_action :sanitize_params
  before_action :set_target_user, :only => [:user, :received, :subscribed]
  before_action :set_link_user
  before_action :setup_pagination
  before_action :setup_conditions_on_comments

  def all
    @comments = @comments.all
    render :list
  end

  def user
    @comments = @comments.where(:author => @target_user)
    render :list
  end

  def received
    @comments = @comments.joins(:changeset).where("changesets.user_id = ?", @target_user.id)
    render :list
  end

  def subscribed
    if @target_user == current_user
      @comments = @comments.joins(:changeset)
                           .joins("inner join changesets_subscribers on changesets.id = changesets_subscribers.changeset_id")
                           .where("changesets_subscribers.subscriber_id = ?", @target_user.id)
      render :list
    else
      # We know we have a logged in user thanks to before_action :require_user
      redirect_to :action => "subscribed", :display_name => current_user.display_name
    end
  end

  private

  def sanitize_params
    @params = params.permit(:display_name, :page)
  end

  # The user to target when fetching comments
  def set_target_user
    @target_user = User.active.where(:display_name => @params[:display_name]).first!
  rescue ActiveRecord::RecordNotFound
    render_unknown_user(display_name) && return
  end

  # The user, if any, which should be linked to in the view
  def set_link_user
    @link_user = @target_user || current_user
  end

  def setup_pagination
    @page = (@params[:page] || 1).to_i
    @page_size = 20
  end

  def setup_conditions_on_comments
    @comments = ChangesetComment.visible
                                .order("changeset_comments.created_at DESC")
                                .offset((@page - 1) * @page_size)
                                .limit(@page_size)
                                .includes(:author, :changeset, :changeset => [:user, :changeset_tags])
  end
end
