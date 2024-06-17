class DiaryCommentsController < ApplicationController
  include UserMethods
  include PaginationMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource

  before_action :lookup_user, :only => :index
  before_action :check_database_writable, :only => [:hide, :unhide]

  allow_thirdparty_images :only => :index

  def index
    @title = t ".title", :user => @user.display_name

    comments = DiaryComment.where(:user => @user)
    comments = comments.visible unless can? :unhide, DiaryComment

    @params = params.permit(:display_name, :before, :after)

    @comments, @newer_comments_id, @older_comments_id = get_page_items(comments, :includes => [:user])
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
end
