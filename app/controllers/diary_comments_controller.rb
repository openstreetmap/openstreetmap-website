class DiaryCommentsController < ApplicationController
  include UserMethods
  include PaginationMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :lookup_user, :only => :index
  before_action :check_database_writable, :only => [:create, :hide, :unhide]

  allow_thirdparty_images :only => :index

  def index
    @title = t ".title", :user => @user.display_name

    comments = DiaryComment.where(:user => @user)
    comments = comments.visible unless can? :unhide, DiaryComment

    @params = params.permit(:display_name, :before, :after)

    @comments, @newer_comments_id, @older_comments_id = get_page_items(comments, :includes => [:user])

    render :partial => "page" if turbo_frame_request_id == "pagination"
  end

  def create
    @entry = DiaryEntry.find(params[:id])
    @comments = @entry.visible_comments
    @diary_comment = @entry.comments.build(comment_params)
    @diary_comment.user = current_user
    if @diary_comment.save

      # Notify current subscribers of the new comment
      @entry.subscribers.visible.each do |user|
        UserMailer.diary_comment_notification(@diary_comment, user).deliver_later if current_user != user
      end

      # Add the commenter to the subscribers if necessary
      @entry.subscriptions.create(:user => current_user) unless @entry.subscribers.exists?(current_user.id)

      redirect_to diary_entry_path(@entry.user, @entry, :anchor => "comment#{@diary_comment.id}")
    else
      render :action => "new"
    end
  rescue ActiveRecord::RecordNotFound
    render "diary_entries/no_such_entry", :status => :not_found
  end

  def hide
    comment = DiaryComment.find(params[:comment])
    comment.update(:visible => false)
    redirect_to diary_entry_path(comment.diary_entry.user, comment.diary_entry)
  end

  def unhide
    comment = DiaryComment.find(params[:comment])
    comment.update(:visible => true)
    redirect_to diary_entry_path(comment.diary_entry.user, comment.diary_entry)
  end

  private

  ##
  # return permitted diary comment parameters
  def comment_params
    params.require(:diary_comment).permit(:body)
  end
end
